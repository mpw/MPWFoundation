//
//  MPWBinaryPlist.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/27/13.
//
//

#import "MPWBinaryPlist.h"

@interface MPWLazyBListArray : NSArray
{
    NSUInteger count;
    MPWBinaryPlist     *plist;
    MPWIntArray        *offsets;
    id  *objs;
    
}
@end

@implementation MPWLazyBListArray


-(NSUInteger)count { return count; }


-initWithPlist:newPlist offsets:(MPWIntArray*)newOffsets
{
    self=[super init];
    if (self ) {
        count=[newOffsets count];
        objs=calloc( count , sizeof *objs);
        offsets=[newOffsets retain];
        plist=[newPlist retain];
    }
    return self;
}

-objectAtIndex:(NSUInteger)anIndex
{
    id obj=nil;
    if ( anIndex < count) {
        obj=objs[anIndex];
        if ( obj == nil)  {
            obj = [plist objectAtIndex:[offsets integerAtIndex:anIndex]];
            objs[anIndex]=[obj retain];
        }
    } else {
        [NSException raise:@"outofbounds" format:@"index %tu out of bounds",anIndex];
    }
    return obj;
}


DEALLOC(
    for (int i=0;i<count;i++) {
        RELEASE(objs[i]);
    }
    free(objs);
    RELEASE(offsets);
    RELEASE(plist);
)


@end


@implementation MPWBinaryPlist

objectAccessor(NSData, data, setData)
boolAccessor(lazyArray, setLazyArray)

static const char headerString[]="bplist00";

#define TRAILER_SIZE (sizeof( uint8_t ) * 2 + sizeof( uint64_t ) * 3)



+(BOOL)isValidBPlist:(NSData*)plistData
{
    const char *bytes=[plistData bytes];
    long len = [plistData length];
    return (len > sizeof headerString) &&
        !strncmp(bytes, headerString, sizeof headerString-1);
}

-initWithData:(NSData*)newPlistData
{
    self=[super init];
    if ( [[self class] isValidBPlist:newPlistData]) {
        [self setData:newPlistData];
        bytes=[data bytes];
        dataLen=[data length];
        rootIndex=-1;
        numObjects=-1;
        [self _readTrailer];
        [self _readOffsetTable];
    } else {
        RELEASE(self);
        self=nil;
    }
    return self;
}
SHORTCONVENIENCE(bplist, WithData:(NSData*)newPlistData)

static inline long readIntegerOfSizeAt( const unsigned char *bytes, long offset, int numBytes  ) {
    long result=0;
    for (int i=0;i<numBytes;i++) {
        result=(result<<8) |  bytes[offset+i];
    }
    return result;
}

-(long)readIntegerOfSize:(int)numBytes atOffset:(long)offset
{
    return readIntegerOfSizeAt(bytes, offset, numBytes);
}

-(void)readNumIntegers:(int)numIntegers atOffset:(long)baseOffset numBytes:(int)numBytes into:(long*)offsetPtrs
{
    for (int i=0;i<numObjects;i++) {
        offsetPtrs[i]=readIntegerOfSizeAt(bytes, baseOffset+i*numBytes, numBytes);
    }
}

-(void)_readOffsetTable
{
    offsets=malloc( numObjects * sizeof *offsets  );
    objects=calloc( numObjects , sizeof *objects  );
    [self readNumIntegers:numObjects atOffset:offsetTableLocation numBytes:offsetIntegerSizeInBytes into:offsets];
}

-(long)offsetOfObjectNo:(long)offsetNo
{
    if ( !offsets ) {
        [self _readOffsetTable];
    }
    return offsets[offsetNo];
}

-(long)_rootOffset
{
    return [self offsetOfObjectNo:[self rootIndex]];
}

static inline int lengthForNibbleAtOffset( int length, const unsigned char *bytes, long *offsetPtr )
{
    long offset=*offsetPtr;
    if ( length==0xf ) {
        int nextHeader=bytes[offset++];
        int byteLen=1<<(nextHeader&0xf);
        length = readIntegerOfSizeAt( bytes, offset, byteLen  ) ;
        offset+=byteLen;
        *offsetPtr=offset;
    }
    return length;
}

-(long)parseIntegerAtOffset:(long)offset
{
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int bottomNibble=bytes[offset] & 0x0f;
    offset++;
    if ( topNibble == 0x1 ){
        return [self readIntegerOfSize:1<<bottomNibble atOffset:offset];
    } else {
        [NSException raise:@"unsupported" format:@"bplist expected integer (0x1), got %x",topNibble];
    }
    return 0;
}


-(long)parseArrayAtIndex:(long)anIndex usingBlock:(ArrayElementBlock)block
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int length=bytes[offset] & 0x0f;
    offset++;
    if ( topNibble == 0xa ){
        length = lengthForNibbleAtOffset(  length, bytes,  &offset );
        for (long i=0;i<length;i++) {
            long nextFileOffset = [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:offset];
            block( self, nextFileOffset, i);
            offset+=offsetReferenceSizeInBytes;

        }
    } else {
        [NSException raise:@"unsupported" format:@"bplist expected dict (0xa), got %x",topNibble];
    }
    return length;
}

-(NSArray*)readArrayAtIndex:(long)anIndex
{
    NSMutableArray *array=[NSMutableArray array];
    [self parseArrayAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long offset, long anIndex) {
        [array addObject:[plist objectAtIndex:offset]];
    }];
    return array;
}



-(NSArray*)readLazyArrayAtIndex:(long)anIndex
{
    MPWIntArray *arrayOffsets=[MPWIntArray array];
    [self parseArrayAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long arrayIndex, long anIndex) {
        [arrayOffsets addInteger:arrayIndex];
    }];
    return [[[MPWLazyBListArray alloc] initWithPlist:self offsets:arrayOffsets] autorelease];
}



-(long)parseDictAtIndex:(long)anIndex usingBlock:(DictElementBlock)block
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int length=bytes[offset] & 0x0f;
    offset++;
    if ( topNibble == 0xd ){
        length = lengthForNibbleAtOffset(  length, bytes,  &offset );
        for (long i=0;i<length;i++) {
            long nextKeyOffset = [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:offset];
            long nextValueOffset = [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:offset+length*offsetReferenceSizeInBytes];
            block( self,  nextKeyOffset,  nextValueOffset, i);
            offset+=offsetReferenceSizeInBytes;
            
        }
    } else {
        [NSException raise:@"unsupported" format:@"bplist expected dict (0xd), got %x",topNibble];
    }
    return length;
}


-(NSDictionary*)readDictAtIndex:(long)anIndex
{
    NSMutableDictionary *dict=nil;
    dict=[NSMutableDictionary dictionary];
    [self parseDictAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long keyOffset,long valueOffset, long anIndex) {
        [dict setObject:[self objectAtIndex:valueOffset] forKey:[self objectAtIndex:keyOffset]];
        }];
    return dict;
}

-(BOOL)isArrayAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    return (bytes[offset] & 0xf0) == 0xa0;
}

-(BOOL)isDictAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    return (bytes[offset] & 0xf0) == 0xd0;
}



-parseObjectAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int bottomNibble=bytes[offset] & 0x0f;
    id result=nil;
    int length=bottomNibble;
    offset++;
    switch ( topNibble) {
        case 0x1:
            result = [NSNumber numberWithLong:[self readIntegerOfSize:1<<bottomNibble atOffset:offset]];
            break;
        case 0x5:
            length = lengthForNibbleAtOffset(  length, bytes,  &offset );
            result = AUTORELEASE([[NSString alloc]
                                  initWithBytes:bytes+offset  length:length encoding:NSASCIIStringEncoding]);
            break;
        case 0x6:
            length = lengthForNibbleAtOffset(  length, bytes,  &offset );
            result = AUTORELEASE([[NSString alloc]
                                  initWithBytes:bytes+offset  length:length*2 encoding:NSUTF16BigEndianStringEncoding]);
            
            break;
        case 0xa:
            if ( lazyArray) {
                result = [self readLazyArrayAtIndex:anIndex];
            } else {
                result = [self readArrayAtIndex:anIndex];
            }
            break;
        case 0xd:
            result = [self readDictAtIndex:anIndex];
            break;
        default:
            [NSException raise:@"unsupported" format:@"unsupported data in bplist: %x",topNibble];
            break;
    }
    return result;
}

-objectAtIndex:(NSUInteger)anIndex
{
    id result=objects[anIndex];
    if ( !result ){
        result=[self parseObjectAtIndex:anIndex];
        objects[anIndex]=RETAIN(result);
    }
    return result;
}


-rootObject
{
    return [self parseObjectAtIndex:rootIndex];
}


-(void)_readTrailer
{
    long trailerOffset=dataLen-TRAILER_SIZE;
    offsetIntegerSizeInBytes=[self readIntegerOfSize:1 atOffset:trailerOffset];
    offsetReferenceSizeInBytes=[self readIntegerOfSize:1 atOffset:trailerOffset+1];
    numObjects=[self readIntegerOfSize:8 atOffset:trailerOffset+2];
    rootIndex=[self readIntegerOfSize:8 atOffset:trailerOffset+10];
    offsetTableLocation=[self readIntegerOfSize:8 atOffset:trailerOffset+18];
}

-(long)_numObjects { return numObjects; }
-(long)rootIndex  { return rootIndex;  }


DEALLOC(
        RELEASE(data);
        for (long i=0;i<numObjects;i++) {
            RELEASE( objects[i]);
        }
        free(objects);
        free(offsets);
)

@end


@implementation MPWBinaryPlist(testing)

+(NSData*)_createBinaryPlist:plistObjects
{
    return [NSPropertyListSerialization dataFromPropertyList:plistObjects format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil];
}

+(void)testRecognizesHeader
{
    EXPECTFALSE([self isValidBPlist:[NSData data]], @"empty plist valid");
    EXPECTTRUE([self isValidBPlist:[self _createBinaryPlist:@"hello world"]], @"string plist");
    EXPECTFALSE([self isValidBPlist:[NSPropertyListSerialization dataFromPropertyList:@"hello world" format:NSPropertyListXMLFormat_v1_0 errorDescription:nil]], @"XML string plist");
}

+(void)testReadTrailerAndOffsets
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(42)]];
    INTEXPECT([bplist _numObjects],  1, @"number of objects");
    INTEXPECT([bplist rootIndex],  0, @"rootIndex" );
    INTEXPECT([bplist _rootOffset], 8, @"offset of root object");
}

+(void)testReadInteger
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(42)]];
    INTEXPECT([[bplist rootObject] intValue],  42, @"root object");
}

+(void)testReadString
{
    NSString *tester=@"Hello World!";
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    IDEXPECT([bplist rootObject],  tester, @"root object");
}

+(void)testReadLongString
{
    NSString *tester=@"Hello World with some more data to get more than 15 characters!";
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    IDEXPECT([bplist rootObject],  tester, @"root object");
}

+(void)testReadIntegerArray
{
    NSArray *tester=@[ @42, @51, @1 , @93];
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    long testArray[20];
    long *arrayPtr=testArray;
    int length=[bplist parseArrayAtIndex:[bplist rootIndex] usingBlock:^( MPWBinaryPlist *bplist, long offset, long anIndex ){
        if (anIndex <10) {
            arrayPtr[anIndex]=[bplist parseIntegerAtOffset:[bplist offsetOfObjectNo:offset]];
        }
    }];
    INTEXPECT(length, 4, @"length");
    INTEXPECT(testArray[0], 42, @"first element");
    INTEXPECT(testArray[1], 51, @"2nd element");
    INTEXPECT(testArray[2], 1, @"3rd element");
    INTEXPECT(testArray[3], 93, @"4th element");
    
}

+(void)testReadIntegerArrayAsObject
{
    NSArray *tester=@[ @42, @51, @1 , @93];
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    NSArray *result=[bplist rootObject];
    INTEXPECT([result count], 4, @"length");
    IDEXPECT(result, tester,@"array");
}

+(void)testReadMixedIntStringArray
{
    NSArray *tester=@[ @42, @"Hello World!", @[ @12, @"nested"], @"last"];
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    NSArray *result=[bplist rootObject];
    INTEXPECT([result count], 4, @"length");
    IDEXPECT(result, tester,@"array");
}

+(void)testReadDict
{
    NSDictionary *tester=@{ @"hello": @"world", @"answer": @42 };
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    NSDictionary *result=[bplist rootObject];
    INTEXPECT([result count], 2, @"length");
    IDEXPECT(result, tester,@"dict");
}

+(void)testReadLazyArray
{
    NSArray *tester=@[ @42, @"Hello World!", @[ @12, @"nested"], @"last"];
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    [bplist setLazyArray:YES];
    NSArray *result=[bplist rootObject];
    EXPECTTRUE([result isKindOfClass:[MPWLazyBListArray class]], @"is a lazy array");
    IDEXPECT(result, tester,@"dict");
}

+testSelectors
{
    return @[ @"testRecognizesHeader",
              @"testReadTrailerAndOffsets",
              @"testReadInteger",
              @"testReadString",
              @"testReadLongString",
              @"testReadIntegerArray",
              @"testReadIntegerArrayAsObject",
              @"testReadMixedIntStringArray",
              @"testReadDict",
              @"testReadLazyArray",
              ];
}

@end