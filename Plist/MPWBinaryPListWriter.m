//
//  MPWBinaryPListWriter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/13.
//
//

#import "MPWBinaryPListWriter.h"
#import <AccessorMacros.h>
#import "MPWIntArray.h"


/*
From:  https://github.com/opensource-apple/CF/blob/master/CFBinaryPList.c
 
 HEADER
 magic number ("bplist")
 file format version
 byte length of plist incl. header, an encoded int number object (as below) [v.2+ only]
 32-bit CRC (ISO/IEC 8802-3:1989) of plist bytes w/o CRC, encoded always as
 "0x12 0x__ 0x__ 0x__ 0x__", big-endian, may be 0 to indicate no CRC [v.2+ only]
 
 OBJECT TABLE
 variable-sized objects
 
 Object Formats (marker byte followed by additional info in some cases)
 null        0000 0000                        // null object [v1+ only]
 bool        0000 1000                        // false
 bool        0000 1001                        // true
 url        0000 1100        string                // URL with no base URL, recursive encoding of URL string [v1+ only]
 url        0000 1101        base string        // URL with base URL, recursive encoding of base URL, then recursive encoding of URL string [v1+ only]
 uuid        0000 1110                        // 16-byte UUID [v1+ only]
 fill        0000 1111                        // fill byte
 int        0001 0nnn        ...                // # of bytes is 2^nnn, big-endian bytes
 real        0010 0nnn        ...                // # of bytes is 2^nnn, big-endian bytes
 date        0011 0011        ...                // 8 byte float follows, big-endian bytes
 data        0100 nnnn        [int]        ...        // nnnn is number of bytes unless 1111 then int count follows, followed by bytes
 string        0101 nnnn        [int]        ...        // ASCII string, nnnn is # of chars, else 1111 then int count, then bytes
 string        0110 nnnn        [int]        ...        // Unicode string, nnnn is # of chars, else 1111 then int count, then big-endian 2-byte uint16_t
 0111 xxxx                        // unused
 uid        1000 nnnn        ...                // nnnn+1 is # of bytes
 1001 xxxx                        // unused
 array        1010 nnnn        [int]        objref*        // nnnn is count, unless '1111', then int count follows
 ordset        1011 nnnn        [int]        objref* // nnnn is count, unless '1111', then int count follows [v1+ only]
 set        1100 nnnn        [int]        objref* // nnnn is count, unless '1111', then int count follows [v1+ only]
 dict        1101 nnnn        [int]        keyref* objref*        // nnnn is count, unless '1111', then int count follows
 1110 xxxx                        // unused
 1111 xxxx                        // unused
 
 OFFSET TABLE
 list of ints, byte size of which is given in trailer
 -- these are the byte offsets into the file
 -- number of these is in the trailer
 
 TRAILER
 byte size of offset ints in offset table
 byte size of object refs in arrays and dicts
 number of offsets in offset table (also is number of objects)
 element # in offset table which is top level object
 offset table offset
 
 Version 1.5 binary plists do not use object references (uid),
 but instead inline the object serialization itself at that point.
 It also doesn't use an offset table or a trailer.  It does have
 an extended header, and the top-level object follows the header.
 
 */

//#if ! TARGET_OS_IPHONE

@implementation MPWBinaryPListWriter



objectAccessor(MPWIntArray*, offsets, setOffsets)
objectAccessor(NSMutableArray*, indexStack, setIndexStack)
objectAccessor(NSMutableArray*, reserveIndexes, setResrveIndexes)
scalarAccessor(MPWIntArray*, currentIndexes, setCurrentIndexes)
objectAccessor(NSMapTable*, objectTable, setObjectTable)

-(id)initWithTarget:(id)aTarget
{

    self=[super initWithTarget:aTarget];
    if (self) {
        inlineOffsetByteSize=4;
    }
    [self setOffsets:[MPWIntArray array]];
    [self setIndexStack:[NSMutableArray array]];
    [self setResrveIndexes:[NSMutableArray array]];
    [self setObjectTable:[NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality valueOptions:NSPointerFunctionsOpaquePersonality]];
    [self writeHeader];
    
    return self;
}


-(void)setTarget:(id)newVar
{
    [super setTarget:newVar];
    headerWritten=NO;
}

-(MPWIntArray*)newIndexes
{
    MPWIntArray *result=[[reserveIndexes lastObject] retain];
    if ( result ) {
        [result reset];
        [reserveIndexes removeLastObject];
    } else {
        result=[MPWIntArray new];
    }
    return result;
}

-(void)pushIndexStack
{
    currentIndexes=[self newIndexes];
    [indexStack addObject:currentIndexes];
    [currentIndexes release];
}

-(MPWIntArray*)popIndexStack
{
    id lastObject=currentIndexes;
    if ( lastObject) {
        [reserveIndexes addObject:lastObject];
    }
    [indexStack removeLastObject];
    currentIndexes=[indexStack lastObject];
    return lastObject;
}

-(void)addIndex:(int)anIndex
{
    [currentIndexes addInteger:anIndex];
}

-(void)beginArray
{
    [self pushIndexStack];
    //    NSLog(@"currentIndexes after beginArray: %@",currentIndexes);
}

-(void)writeArray:(NSArray*)anArray usingElementBlock:(void (^)(MPWBinaryPListWriter* writer,id randomArgument))aBlock
{
    long offset=0;
    offset=(long)[objectTable objectForKey:anArray];
    
    if ( offset ) {
        [currentIndexes addInteger:(int)offset];
    } else {
        if ( [anArray count]) {
            [self beginArray];
            for ( id o in anArray){
                aBlock(self,o);
            }
            [self endArray];
        } else {
            [self _recordByteOffset];
            [self writeCompoundObjectHeader:0xa0 length:0];
            
        }
        [objectTable setObject:(id)(long)[currentIndexes lastInteger] forKey:anArray];

    }
}

-(void)writeArray:(NSArray *)anArray
{
    [self writeArray:anArray usingElementBlock:^( MPWWriteStream *w,id object){
        [w writeObject:object];
    }];
}


-(void)beginDictionary
{
    [self pushIndexStack];
}

static inline int integerToBuffer( unsigned char *buffer, long anInt, int numBytes  )
{
    for (int i=numBytes-1;i>=0;i--) {
        buffer[i]=anInt & 0xff;
        anInt>>=8;
    }
    return numBytes;
}

static inline int taggedIntegerToBuffer( unsigned char *buffer, long anInt, int numBytes, int upperNibble, int lowerNibble  )
{
    buffer[0]=upperNibble | lowerNibble;
    return integerToBuffer(buffer+1, anInt, numBytes)+1;
}

-(void)writeInteger:(long)anInt numBytes:(int)numBytes
{
    unsigned char buffer[16];
    integerToBuffer(buffer, anInt, numBytes);
    TARGET_APPEND((char*)buffer, numBytes);
}

-(void)writeIntArray:(MPWIntArray*)array offset:(int)start skip:(int)stride numBytes:(int)numBytes
{
#define BUFSIZE  8000
    char buffer[BUFSIZE];
    char *cur=buffer;
    int maxCount=(int)[array count];
    int *ptrs=[array integers];
    for (int i=start;i<maxCount;i+=stride) {
        //        NSLog(@"write array[%d]=%d",i,[array integerAtIndex:i]);
        cur+=integerToBuffer((unsigned char*)cur, ptrs[i], numBytes);
        if ( cur-buffer > BUFSIZ-100) {
            TARGET_APPEND(buffer, cur-buffer);
            cur=buffer;
        }
    }
    TARGET_APPEND(buffer, cur-buffer);
}



-(void)writeIntArray:(MPWIntArray*)array numBytes:(int)numBytes
{
    [self writeIntArray:array offset:0 skip:1 numBytes:numBytes];
}

-(void)writeTaggedInteger:(long)anInt
{
    unsigned char buffer[16];
    int log2ofNumBytes=2;
    int numBytes=4;
    taggedIntegerToBuffer(buffer, anInt, numBytes,0x10, log2ofNumBytes);
    TARGET_APPEND((char*)buffer, numBytes+1);
}


-(void)writeCompoundObjectHeader:(int)headerByte length:(long)length
{
    char header=headerByte;
    if ( length < 15 ) {
        header=header | length;
        TARGET_APPEND(&header, 1);
    } else {
        header=header | 0xf;
        TARGET_APPEND(&header, 1);
        [self writeTaggedInteger:length];
    }
}

-(void)writeInteger:(long)anInteger forKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self writeInteger:anInteger];
}

-(void)writeFloat:(float)aFloat forKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self writeFloat:aFloat];
}

-(void)writeObject:(id)anObject forKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self writeObject:anObject];
}

-(void)writeString:(id)anObject forKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self writeObject:anObject];
}

-(void)endArray
{
    @autoreleasepool {
        MPWIntArray *arrayIndexes=[self popIndexStack];
        [self _recordByteOffset];
        [self writeCompoundObjectHeader:0xa0 length:[arrayIndexes count]];
        [self writeIntArray:arrayIndexes numBytes:inlineOffsetByteSize];
    }
}


-(void)endDictionary
{

    MPWIntArray *arrayIndexes=[self popIndexStack];
    [self _recordByteOffset];
    int len=(int)([arrayIndexes count]/2);
    [self writeCompoundObjectHeader:0xd0 length:len];
    [self writeIntArray:arrayIndexes offset:0 skip:2 numBytes:inlineOffsetByteSize];
    [self writeIntArray:arrayIndexes offset:1 skip:2 numBytes:inlineOffsetByteSize];
}


-(void)writeHeader
{
    if ( !headerWritten) {
        TARGET_APPEND("bplist00", 8);
        headerWritten=YES;
    }
}

-(void)_recordByteOffset
{
    
    [currentIndexes addInteger:(int)[offsets count]];
    [offsets addInteger:(int)totalBytes];
}

-(int)currentObjectIndex
{
    return (int)[offsets count];
}


-(void)writeInteger:(long)anInt
{
    char buffer[16];
    int log2ofNumBytes=2;
    int numBytes=4;
    [self _recordByteOffset];
    buffer[0]=0x10 + log2ofNumBytes;
    integerToBuffer((unsigned char*)buffer+1, anInt, numBytes);
    TARGET_APPEND(buffer, numBytes+1);
}


-(void)writeFloat:(float)aFloat
{
    unsigned char buffer[16];
    int log2ofNumBytes=2;
    int numBytes=4;
    unsigned char *floatPtr=(unsigned char*)&aFloat;
    [self _recordByteOffset];
    buffer[0]=0x20 + log2ofNumBytes;
    for (int i=0;i<numBytes;i++) {
        buffer[i+1]=floatPtr[numBytes-i-1];
    }
    TARGET_APPEND((char*)buffer, numBytes+1);
}

-(void)writeString:(NSString*)aString
{
    long offset=0;
    offset=(long)[objectTable objectForKey:aString];
    
    if ( offset ) {
        [currentIndexes addInteger:(int)offset];
    } else {
        [self _recordByteOffset];
        long l=[aString length];
        char buffer[ l + 2];
        [aString getBytes:buffer maxLength:l+1 usedLength:NULL encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0, l) remainingRange:NULL];
        [self writeCompoundObjectHeader:0x50 length:[aString length]];
        TARGET_APPEND(buffer, l);
        [objectTable setObject:(id)(long)[currentIndexes lastInteger] forKey:aString];
    }
}

-(void)writeData:(NSData*)data
{
    {
        [self _recordByteOffset];
        long l=[data length];
        [self writeCompoundObjectHeader:0x40 length:l];
        TARGET_APPEND((char*)[data bytes], l);
        [objectTable setObject:(id)(long)[currentIndexes lastInteger] forKey:data];
    }
}

-(int)offsetTableEntryByteSize
{
    return 4;
}

-(void)writeOffsetTable
{
    offsetOfOffsetTable=[self length];
//    NSLog(@"offsets: %@",offsets);
    [self writeIntArray:offsets numBytes:[self offsetTableEntryByteSize]];
}

-(long)count
{
    return [offsets count];
}

-(long)rootObjectIndex
{
    return [self currentObjectIndex]-1;
}

-(void)writeTrailer
{
    TARGET_APPEND("\0\0\0\0\0\0", 6);
    [self writeInteger:[self offsetTableEntryByteSize] numBytes:1];
    [self writeInteger:inlineOffsetByteSize numBytes:1];
    [self writeInteger:[self count] numBytes:8]; // num objs in table
    [self writeInteger:[self rootObjectIndex] numBytes:8];       // root
    [self writeInteger:offsetOfOffsetTable numBytes:8];       // root
}

-(void)flushLocal
{
//    NSLog(@"writeOffsetTable: %@",offsets);
    [self writeOffsetTable];
//    NSLog(@"writeTrailer");
    [self writeTrailer];
}

-(void)dealloc
{
    [indexStack release];
    [offsets release];
    [reserveIndexes release];
    [objectTable release];
    [super dealloc];
}

@end


#import "DebugMacros.h"

@implementation MPWBinaryPListWriter(tests)

+_plistForData:(NSData*)d
{
//    static int count=1;
//    [d writeToFile:[NSString stringWithFormat:@"/tmp/test-bplist-%d.bplist",count++] atomically:YES];
    id plist=[NSPropertyListSerialization propertyListWithData:d options:0 format:NULL error:NULL];
    return plist;
}

+_plistForStream:(MPWBinaryPListWriter*)aStream
{
    return [self _plistForData:(NSData*)[aStream target]];
}

+_plistViaStream:(id)aPlist
{
    return [self _plistForData:[self process:aPlist]];
}

+(void)testHeaderWrittenAutomaticallyAndIgnoredAfter
{
    MPWBinaryPListWriter *writer=[self stream];
    INTEXPECT( [(NSData*)[writer target] length],8,@"data written before");
    INTEXPECT([writer length], 8, @"bytes written before");
    [writer writeHeader];
    INTEXPECT([writer length], 8, @"bytes written after header");
}


+(void)testWriteSingleIntegerValue
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeInteger:42];
    INTEXPECT([[writer offsets] count], 1, @"should have recored an offset");
    INTEXPECT([[writer offsets] integerAtIndex:0], 8, @"offset of first object");
    [writer flush];
    //    [[writer target] writeToFile:@"/tmp/fourtytwo.plist" atomically:YES];
    NSNumber *n=[self _plistForStream:writer];
    INTEXPECT([n intValue], 42, @"encoded plist value");
}


+(void)testWriteSingleFloatValue
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeFloat:3.14159];
    [writer close];
    NSNumber *n=[self _plistForStream:writer];
    FLOATEXPECTTOLERANCE([n floatValue], 3.14159, 0.000001, @"encoded");
}


+(void)testWriteArrayWithTwoElements
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer beginArray];
    [writer writeInteger:31];
    [writer writeInteger:42];
    [writer endArray];
    [writer flush];
//    [[writer target] writeToFile:@"/tmp/fourtytwo-array.plist" atomically:YES];
    NSArray *a=[self _plistForStream:writer];
//    NSLog(@"a: %@",a);
    INTEXPECT([a count], 2, @"array with 2 values");
    INTEXPECT([[a objectAtIndex:0] intValue], 31, @"array with 2 values");
    INTEXPECT([[a lastObject] intValue], 42, @"array with 2 values");
}

+(void)testWriteNestedArray
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer beginArray];
    [writer writeInteger:31];
    [writer beginArray];
    [writer writeInteger:51];
    [writer writeInteger:123];
    [writer endArray];
    [writer writeInteger:42];
    [writer endArray];
    [writer flush];
//    [[writer target] writeToFile:@"/tmp/nested-array.plist" atomically:YES];
    NSArray *a=[self _plistForStream:writer];
//    NSLog(@"a: %@",a);
    INTEXPECT([a count], 3, @"top level array count");
    NSArray *nested=[a objectAtIndex:1];
    INTEXPECT([nested count], 2, @"nested array count");
    INTEXPECT([[a objectAtIndex:0] intValue], 31, @"array with 2 values");
    INTEXPECT([[a lastObject] intValue], 42, @"array with 2 values");
    INTEXPECT([[nested objectAtIndex:0] intValue], 51, @"array with 2 values");
    INTEXPECT([[nested lastObject] intValue], 123, @"array with 2 values");
}

+(void)testWriteString
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer writeString:@"Hello World!"];
    [writer flush];
    [(NSData*)[writer target] writeToFile:@"/tmp/testWriteString.plist" atomically:YES];
    NSString *s=[self _plistForStream:writer];
    IDEXPECT(s , @"Hello World!", @"the string I wrote");
}

+(void)testWriteData
{
    MPWBinaryPListWriter *writer=[self stream];
    const unsigned char testbytes[]={ 0x42, 0x00, 0xa2, 0x03};
    NSData *data=[NSData dataWithBytes:testbytes length:4];
    [writer writeHeader];
    [writer writeData:data];
    [writer flush];
    NSData *parsed=[self _plistForStream:writer];
    IDEXPECT(parsed , data, @"the data I wrote");
}



+(void)testArrayWithStringsAndInts
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer beginArray];
    [writer writeString:@"What's up doc?"];
    [writer beginArray];
    [writer writeInteger:51];
    [writer writeString:@"nested"];
    [writer endArray];
    [writer writeInteger:42];
    [writer endArray];
    [writer flush];
    //    [[writer target] writeToFile:@"/tmp/nested-array.plist" atomically:YES];
    NSArray *a=[self _plistForStream:writer];
    //    NSLog(@"a: %@",a);
    INTEXPECT([a count], 3, @"top level array count");
    NSArray *nested=[a objectAtIndex:1];
    INTEXPECT([nested count], 2, @"nested array count");
    IDEXPECT([a objectAtIndex:0], @"What's up doc?", @"array with 2 values");
    INTEXPECT([[a lastObject] intValue], 42, @"array with 2 values");
    INTEXPECT([[nested objectAtIndex:0] intValue], 51, @"array with 2 values");
    IDEXPECT([nested lastObject], @"nested", @"array with 2 values");
}


+(void)testSimpleDict
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer beginDictionary];
    [writer writeInteger:42 forKey:@"theAnswer"];
    [writer endDictionary];
    [writer flush];
    //    [[writer target] writeToFile:@"/tmp/nested-array.plist" atomically:YES];
    NSDictionary *a=[self _plistForStream:writer];
    INTEXPECT([a count], 1, @"size of dict");
    IDEXPECT([a objectForKey:@"theAnswer"], @42, @"theAnswer");
    //    NSLog(@"a: %@",a);
}



+(void)testArrayWriter
{
    MPWBinaryPListWriter *localWriter=[self stream];
    NSArray *argument=@[ @1 , @5, @52 ];
    [localWriter writeArray:argument usingElementBlock:^(MPWWriteStream* writer,id randomArgument){
        [(MPWBinaryPListWriter*)writer writeInteger:[randomArgument intValue]];
    }];
    [localWriter flush];
    NSArray *a=[self _plistForStream:localWriter];
    INTEXPECT([a count], 3, @"size of array");
    IDEXPECT([a lastObject], @52, @"theAnswer");
    //    NSLog(@"a: %@",a);
}


+(void)testLargerArray
{
    MPWBinaryPListWriter *writer=[self stream];
    NSMutableArray *input=[NSMutableArray array];
    for (int i=0;i<15;i++) {
        [input addObject:@(i)];
    }
    [writer writeArray:input usingElementBlock:^(MPWWriteStream* aWriter,id randomArgument){
        [(MPWBinaryPListWriter*)aWriter writeInteger:[randomArgument intValue]];
    }];
    [writer close];
    NSArray *a=[self _plistForStream:writer];
    INTEXPECT([a count], 15, @"size of array");
    IDEXPECT([a lastObject], @14, @"theAnswer");
    //    NSLog(@"a: %@",a);
}

+(void)testWriteObjectAndStreamMessage
{
    IDEXPECT([self _plistViaStream:@"Hello World!"], @"Hello World!",@"process single string");

    INTEXPECT([[self _plistViaStream:@(42)] intValue], 42,@"process single integer");
    FLOATEXPECTTOLERANCE([[self _plistViaStream:@3.14159] floatValue], 3.14159,0.001,@"process single float");

}

+(void)testWriteWriteGenericArray
{
    NSArray *a=@[ @"abced", @(42), @2.713 ];
    NSArray *result=[self _plistViaStream:a];
    INTEXPECT([result count], 3, @"result count");
}

+(void)testWriteWriteGenericDictionary
{
    NSDictionary *a=@{ @"a": @"hello world", @"b": @42 };
    NSArray *result=[self _plistViaStream:a];
    NSLog(@"result: %@",result);
    INTEXPECT([result count], 2, @"result count");
}

+testSelectors
{
    return @[
             @"testHeaderWrittenAutomaticallyAndIgnoredAfter",
             @"testWriteSingleIntegerValue",
             @"testWriteSingleFloatValue",
             @"testWriteArrayWithTwoElements",
             @"testWriteNestedArray",
             @"testWriteString",
             @"testWriteData",
             @"testArrayWithStringsAndInts",
             @"testSimpleDict",
             @"testArrayWriter",
             @"testLargerArray",
             @"testWriteObjectAndStreamMessage",
             @"testWriteWriteGenericArray",
             @"testWriteWriteGenericDictionary",
             ];
}

@end


//#endif
