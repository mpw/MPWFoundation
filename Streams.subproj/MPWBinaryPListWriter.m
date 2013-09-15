//
//  MPWBinaryPListWriter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/13.
//
//

#import "MPWBinaryPListWriter.h"
#import "AccessorMacros.h"
#import "MPWIntArray.h"

/*
 From CFBinaryPlist.c
 
 HEADER
 magic number ("bplist")
 file format version
 
 OBJECT TABLE
 variable-sized objects
 
 Object Formats (marker byte followed by additional info in some cases)
 null	0000 0000
 bool	0000 1000			// false
 bool	0000 1001			// true
 fill	0000 1111			// fill byte
 int	0001 nnnn	...		// # of bytes is 2^nnnn, big-endian bytes
 real	0010 nnnn	...		// # of bytes is 2^nnnn, big-endian bytes
 date	0011 0011	...		// 8 byte float follows, big-endian bytes
 data	0100 nnnn	[int]	...	// nnnn is number of bytes unless 1111 then int count follows, followed by bytes
 string	0101 nnnn	[int]	...	// ASCII string, nnnn is # of chars, else 1111 then int count, then bytes
 string	0110 nnnn	[int]	...	// Unicode string, nnnn is # of chars, else 1111 then int count, then big-endian 2-byte uint16_t
 0111 xxxx			// unused
 uid	1000 nnnn	...		// nnnn+1 is # of bytes
 1001 xxxx			// unused
 array	1010 nnnn	[int]	objref*	// nnnn is count, unless '1111', then int count follows
 1011 xxxx			// unused
 set	1100 nnnn	[int]	objref* // nnnn is count, unless '1111', then int count follows
 dict	1101 nnnn	[int]	keyref* objref*	// nnnn is count, unless '1111', then int count follows
 1110 xxxx			// unused
 1111 xxxx			// unused
 
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
 
 */


@implementation MPWBinaryPListWriter

objectAccessor(MPWIntArray, offsets, setOffsets)
objectAccessor(NSMutableArray, indexStack, setIndexStack)
objectAccessor(NSMutableArray, reserveIndexes, setResrveIndexes)
objectAccessor(MPWIntArray, currentIndexes, setCurrentIndexes)
objectAccessor(NSMapTable, objectTable, setObjectTable)

-(id)initWithTarget:(id)aTarget
{

    self=[super initWithTarget:aTarget];
    [self setOffsets:[MPWIntArray array]];
    [self setIndexStack:[NSMutableArray array]];
    [self setResrveIndexes:[NSMutableArray array]];
    [self setObjectTable:[NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality valueOptions:NSPointerFunctionsOpaquePersonality]];
    return self;
}




-(MPWIntArray*)getIndexes
{
    MPWIntArray *result=[reserveIndexes lastObject];
    if ( result ) {
        [result reset];
        [reserveIndexes removeLastObject];
    } else {
        result=[MPWIntArray array];
    }
    return result;
}

-(void)pushIndexStack
{
    if ( currentIndexes) {
        [indexStack addObject:currentIndexes];
    }
    [self setCurrentIndexes:[self getIndexes]];
}

-(MPWIntArray*)popIndexStack
{
    id lastObject=[currentIndexes retain];
    if ( lastObject) {
        [reserveIndexes addObject:lastObject];
    }
    id fromStack=[indexStack lastObject];
    [self setCurrentIndexes:fromStack];
    if ( fromStack) {
        [indexStack removeLastObject];
    }
    return [lastObject autorelease];
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

-(void)writeArray:(NSArray*)anArray usingElementBlock:(WriterBlock)aBlock
{
    [self beginArray];
    for (int i=0;i<[anArray count];i++) {
        aBlock(self,[anArray objectAtIndex:i]);
    }
    [self endArray];
}


-(void)beginDictionary
{
    [self pushIndexStack];
    //    NSLog(@"currentIndexes after beginArray: %@",currentIndexes);
}

static inline int integerToBuffer( unsigned char *buffer, long anInt, int numBytes  )
{
    for (int i=numBytes-1;i>=0;i--) {
        buffer[i]=anInt & 0xff;
        anInt>>=8;
    }
    return numBytes;
}

-(void)writeInteger:(long)anInt numBytes:(int)numBytes
{
    unsigned char buffer[16];
    integerToBuffer(buffer, anInt, numBytes);
    TARGET_APPEND(buffer, numBytes);
}

-(void)writeIntArray:(MPWIntArray*)array offset:(int)start skip:(int)stride numBytes:(int)numBytes
{
#define BUFSIZE  8000
    unsigned char buffer[BUFSIZE];
    unsigned char *cur=buffer;
    int maxCount=[array count];
    int *ptrs=[array integers];
    for (int i=start;i<maxCount;i+=stride) {
        //        NSLog(@"write array[%d]=%d",i,[array integerAtIndex:i]);
        cur+=integerToBuffer(cur, ptrs[i], numBytes);
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
    buffer[0]=0x10 + log2ofNumBytes;
    for (int i=numBytes-1;i>=0;i--) {
        buffer[i+1]=anInt & 0xff;
        anInt>>=8;
    }
    TARGET_APPEND(buffer, numBytes+1);
}


-(void)writeHeader:(int)headerByte length:(int)length
{
    unsigned char header=headerByte;
    if ( length < 15 ) {
        header=header | length;
        TARGET_APPEND(&header, 1);
    } else {
        header=header | 0xf;
        TARGET_APPEND(&header, 1);
        [self writeTaggedInteger:length];
    }
}

-(void)writeInt:(int)anInteger forKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self writeAndRecordTaggedInteger:anInteger];
}

-(void)endArray
{
    @autoreleasepool {
        MPWIntArray *arrayIndexes=[self popIndexStack];
        [self _recordByteOffset];
        [self writeHeader:0xa0 length:[arrayIndexes count]];
        [self writeIntArray:arrayIndexes numBytes:[self inlineOffsetEntryByteSize]];
    }
}


-(void)endDictionary
{
    @autoreleasepool {
        MPWIntArray *arrayIndexes=[self popIndexStack];
        [self _recordByteOffset];
        [self writeHeader:0xd0 length:[arrayIndexes count]/2];
        [self writeIntArray:arrayIndexes offset:0 skip:2 numBytes:[self inlineOffsetEntryByteSize]];
        [self writeIntArray:arrayIndexes offset:1 skip:2 numBytes:[self inlineOffsetEntryByteSize]];
    }
}


-(void)writeHeader
{
    TARGET_APPEND("bplist00", 8);
}

-(void)_recordByteOffset
{
    [currentIndexes addInteger:[offsets count]];
    [offsets addInteger:[self length]];
}

-(int)currentObjectIndex
{
    return [offsets count];
}


-(void)writeAndRecordTaggedInteger:(long)anInt
{
    unsigned char buffer[16];
    int log2ofNumBytes=2;
    int numBytes=4;
    [self _recordByteOffset];
    buffer[0]=0x10 + log2ofNumBytes;
    for (int i=numBytes-1;i>=0;i--) {
        buffer[i+1]=anInt & 0xff;
        anInt>>=8;
    }
    TARGET_APPEND(buffer, numBytes+1);
}

-(void)writeString:(NSString*)aString
{
    int offset=0;
    offset=[objectTable objectForKey:aString];
    
    if ( offset ) {
        [currentIndexes addInteger:offset];
    } else {
        [self _recordByteOffset];
        int l=[aString length];
        char buffer[ l + 1];
        [aString getBytes:buffer maxLength:l usedLength:NULL encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0, l) remainingRange:NULL];
        [self writeHeader:0x50 length:[aString length]];
        TARGET_APPEND(buffer, l);
        [objectTable setObject:(id)[currentIndexes lastInteger] forKey:aString];
    }
}

-(int)offsetTableEntryByteSize
{
    return 4;
}

-(int)inlineOffsetEntryByteSize
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
    [self writeInteger:[self inlineOffsetEntryByteSize] numBytes:1];
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

@end


#import "DebugMacros.h"

@implementation MPWBinaryPListWriter(tests)

+_plistForStream:(MPWBinaryPListWriter*)aStream
{
    NSData *d=[aStream target];
    id plist=[NSPropertyListSerialization propertyListWithData:d options:0 format:NULL error:nil];
    return plist;
}

+(void)testWriteHeader
{
    MPWBinaryPListWriter *writer=[self stream];
    INTEXPECT( [[writer target] length],0,@"data written before");
    INTEXPECT([writer length], 0, @"bytes written before");
    [writer writeHeader];
    INTEXPECT([writer length], 8, @"bytes written after header");
}


+(void)testWriteSingleIntegerValue
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer writeAndRecordTaggedInteger:42];
    INTEXPECT([[writer offsets] count], 1, @"should have recored an offset");
    INTEXPECT([[writer offsets] integerAtIndex:0], 8, @"offset of first object");
    [writer flush];
//    [[writer target] writeToFile:@"/tmp/fourtytwo.plist" atomically:YES];
    NSNumber *n=[self _plistForStream:writer];
    INTEXPECT([n intValue], 42, @"encoded plist value");
}


+(void)testWriteArrayWithTwoElements
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer beginArray];
    [writer writeAndRecordTaggedInteger:31];
    [writer writeAndRecordTaggedInteger:42];
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
    [writer writeAndRecordTaggedInteger:31];
    [writer beginArray];
    [writer writeAndRecordTaggedInteger:51];
    [writer writeAndRecordTaggedInteger:123];
    [writer endArray];
    [writer writeAndRecordTaggedInteger:42];
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
    NSString *s=[self _plistForStream:writer];
    IDEXPECT(s , @"Hello World!", @"the string I wrote");
}



+(void)testArrayWithStringsAndInts
{
    MPWBinaryPListWriter *writer=[self stream];
    [writer writeHeader];
    [writer beginArray];
    [writer writeString:@"What's up doc?"];
    [writer beginArray];
    [writer writeAndRecordTaggedInteger:51];
    [writer writeString:@"nested"];
    [writer endArray];
    [writer writeAndRecordTaggedInteger:42];
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
    [writer writeHeader];
    [writer beginDictionary];
    [writer writeInt:42 forKey:@"theAnswer"];
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
    MPWBinaryPListWriter *writer=[self stream];
    NSArray *argument=@[ @1 , @5, @52 ];
    [writer writeHeader];
    [writer writeArray:argument usingElementBlock:^(MPWBinaryPListWriter* writer,id randomArgument){
        [writer writeAndRecordTaggedInteger:[randomArgument intValue]];
    }];
    [writer flush];
    NSArray *a=[self _plistForStream:writer];
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
    [writer writeHeader];
    [writer writeArray:input usingElementBlock:^(MPWBinaryPListWriter* writer,id randomArgument){
        [writer writeAndRecordTaggedInteger:[randomArgument intValue]];
    }];
    [writer flush];
    NSArray *a=[self _plistForStream:writer];
    INTEXPECT([a count], 15, @"size of array");
    IDEXPECT([a lastObject], @14, @"theAnswer");
    //    NSLog(@"a: %@",a);
}



+testSelectors
{
    return @[
             @"testWriteHeader",
             @"testWriteSingleIntegerValue",
             @"testWriteArrayWithTwoElements",
             @"testWriteNestedArray",
             @"testWriteString",
             @"testArrayWithStringsAndInts",
             @"testSimpleDict",
             @"testArrayWriter",
             @"testLargerArray",
             ];
}

@end

