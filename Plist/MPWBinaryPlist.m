//
//  MPWBinaryPlist.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/27/13.
//
//

#import "MPWBinaryPlist.h"
#import <AccessorMacros.h>
#import "MPWIntArray.h"


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
            obj = [plist objectAtIndex:[offsets integerAtIndex:(int)anIndex]];
            objs[anIndex]=[obj retain];
        }
    } else {
        [NSException raise:@"outofbounds" format:@"index %tu out of bounds",anIndex];
    }
    return obj;
}


ARCDEALLOC(
    for (int i=0;i<count;i++) {
        RELEASE(objs[i]);
    }
    free(objs);
    RELEASE(offsets);
    RELEASE(plist);
)


@end


@implementation MPWBinaryPlist
{
    NSData  *data;
    const unsigned char *bytes;
    long  dataLen;
    long    rootIndex;
    long    numObjects;
    long    offsetTableLocation;
    long    *offsets;
    id      *objects;
    int     offsetIntegerSizeInBytes;
    int     offsetReferenceSizeInBytes;
    BOOL    lazyArray;
    long     currentObjectNo;
    long     currentKeyNo;
    MPWIntArray *objectNoStack;
    MPWIntArray *keyNoStack;
    
    long    currentDictOffset,currentDictLength,currentDictIndex;
}

objectAccessor(NSData*, data, setData)
objectAccessor(MPWIntArray*, objectNoStack, setObjectNoStack)
objectAccessor(MPWIntArray*, keyNoStack, setKeyNoStack)
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

CONVENIENCEANDINIT(bplist, WithData:(NSData*)newPlistData)
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
        currentObjectNo=rootIndex;
        [self setKeyNoStack:[MPWIntArray array]];
        [self setObjectNoStack:[MPWIntArray array]];
    } else {
        RELEASE(self);
        self=nil;
    }
    return self;
}

static inline long readIntegerOfSizeAt( const unsigned char *bytes, long offset, int numBytes  ) {
    long result=0;
    for (int i=0;i<numBytes;i++) {
        result=(result<<8) |  bytes[offset+i];
    }
    return result;
}

-(void)pushCurrentObjectNo
{
    [objectNoStack addInteger:(int)currentObjectNo];
}

-(void)popObjectNo
{
    currentObjectNo=[objectNoStack lastInteger];
    [objectNoStack removeLastObject];
}

-(long)readIntegerOfSize:(int)numBytes atOffset:(long)offset
{
    return readIntegerOfSizeAt(bytes, offset, numBytes);
}

-(void)readNumIntegers:(long)numIntegers atOffset:(long)baseOffset numBytes:(int)numBytes into:(long*)offsetPtrs
{
    for (long i=0;i<numObjects;i++) {
        offsetPtrs[i]=readIntegerOfSizeAt(bytes, baseOffset+i*numBytes, numBytes);
    }
}

-(void)_readOffsetTable
{
    offsets=malloc( numObjects * sizeof *offsets  );
    objects=calloc( numObjects , sizeof *objects  );
    [self readNumIntegers:numObjects atOffset:offsetTableLocation numBytes:(int)offsetIntegerSizeInBytes into:offsets];
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
        length = (int)readIntegerOfSizeAt( bytes, offset, byteLen  ) ;
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
        [self pushCurrentObjectNo];
        length = lengthForNibbleAtOffset(  length, bytes,  &offset );
        for (long i=0;i<length;i++) {
            long nextIndex = [self readIntegerOfSize:(int)offsetReferenceSizeInBytes atOffset:offset];
            currentObjectNo=nextIndex;
            block( self, nextIndex, i);
            offset+=offsetReferenceSizeInBytes;

        }
        [self popObjectNo];

    } else {
        [NSException raise:@"unsupported" format:@"bplist expected dict (0xa), got %x",topNibble];
    }
    return length;
}

-(long)parseArrayUsingBlock:(ArrayElementBlock)block
{
    return [self parseArrayAtIndex:currentObjectNo usingBlock:block];
}

-(NSArray*)readArrayAtIndex:(long)anIndex
{
    NSMutableArray *array=[NSMutableArray array];
    [self parseArrayAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long offset, long someIndex) {
        [array addObject:[plist objectAtIndex:offset]];
    }];
    return array;
}



-(NSArray*)readLazyArrayAtIndex:(long)anIndex
{
    MPWIntArray *arrayOffsets=[MPWIntArray array];
    [self parseArrayAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long arrayIndex, long someInex) {
        [arrayOffsets addInteger:(int)arrayIndex];
    }];
    return [[[MPWLazyBListArray alloc] initWithPlist:self offsets:arrayOffsets] autorelease];
}

-(long)keyIndexAtCurrentDictIndex:(long)anIndex
{
    return [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:currentDictOffset+anIndex*offsetReferenceSizeInBytes];
}

-(long)valueIndexAtCurrentDictIndex:(long)anIndex
{
    if ( anIndex >=0 && anIndex < currentDictLength) {
        return [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:currentDictOffset+(anIndex+currentDictLength)*offsetReferenceSizeInBytes];
    } else {
        [NSException raise:@"rangecheck" format:@"dict index %ld out of range: %d",anIndex,(int)currentDictLength];
    }
    return 0;
}

-(long)decodeIntForKey:(NSString*)aKey
{
    if ( [self verifyKey:aKey forIndex:[self keyIndexAtCurrentDictIndex:currentDictIndex]]) {
        return [self parseIntegerAtOffset:offsets[[self valueIndexAtCurrentDictIndex:currentDictIndex++]]];
    } else {
        [NSException raise:@"keycheck" format:@"dict index %d expected key %@ got %@",(int)currentDictIndex,aKey,[self objectAtIndex:currentDictIndex]];
    }
    return 0;
}

-(double)decodeDoubleForKey:(NSString*)aKey
{
    return [self readDoubleAtIndex:[self valueIndexAtCurrentDictIndex:currentDictIndex++]];
}

-(id)decodeObjectForKey:(NSString*)aKey
{
    return [self objectAtIndex:[self valueIndexAtCurrentDictIndex:currentDictIndex++]];
}

-(id)decodeObjectOfClass:(Class)aClass forKey:(NSString*)aKey
{
    long anIndex =[self valueIndexAtCurrentDictIndex:currentDictIndex++];
    id instance=NSAllocateObject(aClass, 0, NULL);
    [self parseDictAtIndex:anIndex usingContentBlock:^(MPWBinaryPlist *plist, long keyOffset, long valueOffset, long someIndex) {
        [instance initWithCoder:(NSCoder*)plist];
    }];
    return instance;
}

-(id)decodeArrayWithElementsOfClass:(Class)aClass forKey:(NSString*)aKey
{
    long anIndex =[self valueIndexAtCurrentDictIndex:currentDictIndex++];
    NSMutableArray *result=[NSMutableArray array];
    [self parseArrayAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long offset, long someIndex) {
        [result addObject:[plist decodeObjectOfClass:aClass forKey:nil]];
    }];
    return result;
}



-(long)parseArrayAtKey:(NSString*)aKey usingBlock:(ArrayElementBlock)block
{
    long anIndex=[self valueIndexAtCurrentDictIndex:currentDictIndex++];
    return [self parseArrayAtIndex:anIndex usingBlock:block];
}

-(BOOL)isArrayAtKey:(NSString*)aKey
{
    long anIndex=[self valueIndexAtCurrentDictIndex:currentDictIndex];
    return [self isArrayAtIndex:anIndex];
}



-(long)parseDictAtIndex:(long)anIndex usingContentBlock:(DictElementBlock)block
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int length=bytes[offset] & 0x0f;
    
    long oldLength=currentDictLength;
    long oldOffset=currentDictOffset;
    long oldIndex=currentDictIndex;
    offset++;
    if ( topNibble == 0xd ){
        [self pushCurrentObjectNo];
        currentDictIndex=0;
        length = lengthForNibbleAtOffset(  length, bytes,  &offset );
        currentDictOffset=offset;
        currentDictLength=length;
        
        block( self,  0,  0, length);

        [self popObjectNo];
    } else {
        [NSException raise:@"unsupported" format:@"bplist expected dict (0xd), got %x",topNibble];
    }
    currentDictLength=oldLength;
    currentDictOffset=oldOffset;
    currentDictIndex=oldIndex;
    
    return length;
}


-(long)parseDictAtIndex:(long)anIndex usingBlock:(DictElementBlock)block
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    int length=bytes[offset] & 0x0f;
    offset++;
    if ( topNibble == 0xd ){
        [self pushCurrentObjectNo];
        length = lengthForNibbleAtOffset(  length, bytes,  &offset );
        for (long i=0;i<length;i++) {
            long nextKeyOffset = [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:offset];
            long nextValueOffset = [self readIntegerOfSize:offsetReferenceSizeInBytes atOffset:offset+length*offsetReferenceSizeInBytes];
            currentObjectNo=nextValueOffset;
            currentKeyNo=nextKeyOffset;
            block( self,  nextKeyOffset,  nextValueOffset, i);
           offset+=offsetReferenceSizeInBytes;
            
        }
        [self popObjectNo];
    } else {
        [NSException raise:@"unsupported" format:@"bplist expected dict (0xd), got %x",topNibble];
    }
    return length;
}

-(long)parseDictUsingBlock:(DictElementBlock)block
{
    return [self parseDictAtIndex:currentObjectNo usingBlock:block];
}

-(long)parseDictUsingContentBlock:(DictElementBlock)block
{
    return [self parseDictAtIndex:currentObjectNo usingContentBlock:block];
}

-(NSDictionary*)readDictAtIndex:(long)anIndex
{
    NSMutableDictionary *dict=nil;
    dict=[NSMutableDictionary dictionary];
    [self parseDictAtIndex:anIndex usingBlock:^(MPWBinaryPlist *plist, long keyOffset,long valueOffset, long someIndex) {
        [dict setObject:[self objectAtIndex:valueOffset] forKey:[self objectAtIndex:keyOffset]];
        }];
    return dict;
}

-(BOOL)isArrayAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    return (bytes[offset] & 0xf0) == 0xa0;
}

-(BOOL)isArray
{
    return [self isArrayAtIndex:currentObjectNo];
}

-(BOOL)isDictAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    return (bytes[offset] & 0xf0) == 0xd0;
}

-(BOOL)isDict
{
    return [self isDictAtIndex:currentObjectNo];
}

static inline double readRealAtIndex( long  anIndex, const unsigned char *bytes, long *offsets )
{
    double result=0;
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    char buffer[8];
    int byteSize =1<<bottomNibble;
    for (int i=0;i<byteSize;i++) {
        buffer[i]=bytes[offset+byteSize-i];
    }
    if ( byteSize==4) {
        result = *(float*)buffer;
    } else if ( byteSize==8) {
        result = *(double*)buffer;
    } else {
        [NSException raise:@"invalidformat" format:@"invalid length of real: %d",byteSize];
    }
    return result;
}

-(float)readFloatAtIndex:(long)anIndex
{
    return readRealAtIndex(  anIndex, bytes, offsets );
}

-(double)readDoubleAtIndex:(long)anIndex
{
    return readRealAtIndex(  anIndex, bytes, offsets );
}

-(float)readFloat
{
    return readRealAtIndex(  currentObjectNo, bytes, offsets );
}

-(double)readDouble
{
    return readRealAtIndex(  currentObjectNo, bytes, offsets );
}

-(NSNumber*)readIntegerNumberAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    return [NSNumber numberWithLong:readIntegerOfSizeAt(bytes, offset+1, 1<<bottomNibble)];
}

-(NSNumber*)readRealNumberAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    return ((1<<bottomNibble)==4) ? [NSNumber numberWithFloat:[self readFloatAtIndex:anIndex]] : ((1<<bottomNibble)==8) ?  [NSNumber numberWithDouble:[self readDoubleAtIndex:anIndex]] : nil;
}

-(NSString*)readASCIIStringAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    offset++;
    long length = lengthForNibbleAtOffset(  bottomNibble, bytes,  &offset );
    return AUTORELEASE([[NSString alloc]
                        initWithBytes:bytes+offset  length:length encoding:NSASCIIStringEncoding]);
}

-(NSData*)readDataAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    offset++;
    long length = lengthForNibbleAtOffset(  bottomNibble, bytes,  &offset );
    return AUTORELEASE([[NSData alloc]
                        initWithBytes:bytes+offset  length:length]);
}

-(NSString*)readUTF16StringAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int bottomNibble=bytes[offset] & 0x0f;
    offset++;
    long length = lengthForNibbleAtOffset(  bottomNibble, bytes,  &offset );
    return AUTORELEASE([[NSString alloc]
                        initWithBytes:bytes+offset  length:length*2 encoding:NSUTF16BigEndianStringEncoding]);
}

-parseObjectAtIndex:(long)anIndex
{
    long offset=offsets[anIndex];
    int topNibble=(bytes[offset] & 0xf0) >> 4;
    id result=nil;
    switch ( topNibble) {
        case 0x1:
            result = [self readIntegerNumberAtIndex:anIndex];
            break;
        case 0x2:
            result = [self readRealNumberAtIndex:anIndex];
            break;
        case 0x4:
            result = [self readDataAtIndex:anIndex];
            break;
        case 0x5:
            result = [self readASCIIStringAtIndex:anIndex];
            break;
        case 0x6:
            result = [self readUTF16StringAtIndex:anIndex];
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

static inline id objectAtIndex( MPWBinaryPlist *self, NSUInteger anIndex )
{
    id result=self->objects[anIndex];
    if ( !result ){
        result=[self parseObjectAtIndex:anIndex];
        self->objects[anIndex]=RETAIN(result);
    }
    return result;
}

-objectAtIndex:(NSUInteger)anIndex
{
    return objectAtIndex(self, anIndex);
}

-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(id)object
{
    RETAIN(object);
    RELEASE(objects[anIndex]);
    objects[anIndex]=object;
}

-(long)currentInt
{
    return [self parseIntegerAtOffset:offsets[currentObjectNo]];
}

-currentObject
{
    return [self objectAtIndex:currentObjectNo];
}

-rootObject
{
    return [self parseObjectAtIndex:rootIndex];
}


-(void)_readTrailer
{
    long trailerOffset=dataLen-TRAILER_SIZE;
    offsetIntegerSizeInBytes=(int)[self readIntegerOfSize:1 atOffset:trailerOffset];
    offsetReferenceSizeInBytes=(int)[self readIntegerOfSize:1 atOffset:trailerOffset+1];
    numObjects=[self readIntegerOfSize:8 atOffset:trailerOffset+2];
    rootIndex=[self readIntegerOfSize:8 atOffset:trailerOffset+10];
    offsetTableLocation=[self readIntegerOfSize:8 atOffset:trailerOffset+18];
}

-(NSUInteger)count { return numObjects; }
-(long)rootIndex  { return rootIndex;  }

-(BOOL)verifyKey:keyToCheck forIndex:(long)keyOffset
{
    id keyInArchive=objectAtIndex(self, keyOffset );
    if ( keyInArchive == keyToCheck) {
        return YES;
    } else {
        if ( [keyInArchive isEqual:keyToCheck] ) {
            [self replaceObjectAtIndex:keyOffset withObject:keyToCheck];
            return YES;
        }
    }
    return NO;
}

ARCDEALLOC(
        RELEASE(data);
        for (long i=0;i<numObjects;i++) {
            RELEASE( objects[i]);
        }
        free(objects);
        free(offsets);
        RELEASE(objectNoStack);
        RELEASE(keyNoStack);
)

@end

#import "DebugMacros.h"

@implementation MPWBinaryPlist(testing)

+(NSData*)_createBinaryPlist:plistObjects
{
    return [NSPropertyListSerialization dataWithPropertyList:plistObjects format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
}

+(void)testRecognizesHeader
{
    EXPECTFALSE([self isValidBPlist:[NSData data]], @"empty plist valid");
    EXPECTTRUE([self isValidBPlist:[self _createBinaryPlist:@"hello world"]], @"string plist");
    EXPECTFALSE([self isValidBPlist:[NSPropertyListSerialization dataWithPropertyList:@"hello world" format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL]], @"XML string plist");
}

+(void)testReadTrailerAndOffsets
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(42)]];
    INTEXPECT([bplist count],  1, @"number of objects");
    INTEXPECT([bplist rootIndex],  0, @"rootIndex" );
    INTEXPECT([bplist _rootOffset], 8, @"offset of root object");
}

+(void)testReadInteger
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(42)]];
    INTEXPECT([[bplist rootObject] intValue],  42, @"root object");
}


+(void)testReadReal
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(3.14159)]];
    FLOATEXPECTTOLERANCE([[bplist rootObject] doubleValue], 3.14159, 0.000001, @"float or double");
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
    long length=[bplist parseArrayAtIndex:[bplist rootIndex] usingBlock:^( MPWBinaryPlist *aBplist, long offset, long anIndex ){
        if (anIndex <10) {
            arrayPtr[anIndex]=[aBplist currentInt];
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

+(void)testVerifyDictKeys
{
    NSString *key1=@"hello";
    NSString *key2=@"answer";
    NSDictionary *tester=@{ key1: @"world", key2: @42 };
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    [bplist parseDictUsingBlock:^(MPWBinaryPlist *plist, long keyOffset, long valueOffset, long anIndex) {
        switch (anIndex) {
            case 0:
                EXPECTTRUE([plist verifyKey:key1 forIndex:keyOffset], @"key1 matches");
                EXPECTFALSE([plist verifyKey:key2 forIndex:keyOffset], @"key2 matches case 0");
                break;
            case 1:
                EXPECTTRUE([plist verifyKey:key2 forIndex:keyOffset], @"key2 matches");
                EXPECTFALSE([plist verifyKey:key1 forIndex:keyOffset], @"key1 matches");
                break;
        }
    } ];
}


+(void)testReadDictActively
{
    NSString *key1=@"hello";
    NSString *key2=@"answer";
    NSDictionary *tester=@{ key1: @"world", key2: @42 };
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:tester]];
    [bplist parseDictUsingContentBlock:^(MPWBinaryPlist *plist, long keyOffset, long valueOffset, long anIndex) {
        IDEXPECT([plist decodeObjectForKey:key1], @"world", @"readObjectForKey");
        INTEXPECT([plist decodeIntForKey:key2], 42, @"decodeIntForKey");
    } ];
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

+(void)testReadPlistWithDataContents
{
    unsigned const char testData[]={ 0x23, 0x45, 0x00, 0x81, };
    NSMutableData *d=[NSMutableData dataWithBytes:testData length:4];
    for (int i=0;i<6;i++) {
        [d appendData:d];
    }
    INTEXPECT( [d length], 256, @"length");
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:d]];
    NSData *parsed=[bplist rootObject];
    IDEXPECT( d, parsed, @"got the same data");
}


+testSelectors
{
    return @[ @"testRecognizesHeader",
              @"testReadTrailerAndOffsets",
              @"testReadInteger",
              @"testReadReal",
              @"testReadString",
              @"testReadLongString",
              @"testReadIntegerArray",
              @"testReadIntegerArrayAsObject",
              @"testReadMixedIntStringArray",
              @"testReadDict",
              @"testVerifyDictKeys",
              @"testReadDictActively",
              @"testReadLazyArray",
              @"testReadLazyArray",
              @"testReadPlistWithDataContents",
              ];
}

@end
