//
//  MPWBinaryPlist.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/27/13.
//
//

#import "MPWBinaryPlist.h"

@implementation MPWBinaryPlist

objectAccessor(NSData, data, setData)

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
    return [self offsetOfObjectNo:[self _rootIndex]];
}

-parseObjectAtOffset:(long)offset
{
    int topNibble=bytes[offset] & 0xf0;
    int bottomNibble=bytes[offset] & 0x0f;
    id result=nil;
    offset++;
    switch ( topNibble) {
        case 0x10:
            result = [NSNumber numberWithLong:[self readIntegerOfSize:1<<bottomNibble atOffset:offset]];
            break;
        default:
            [NSException raise:@"unsupported" format:@"unsupported data in bplist"];
            break;
    }
    return result;
}

-rootObject
{
    return [self parseObjectAtOffset:[self _rootOffset]];
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
-(long)_rootIndex  { return rootIndex;  }

SHORTCONVENIENCE(bplist, WithData:(NSData*)newPlistData)

DEALLOC(
        RELEASE(data);
        
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
    INTEXPECT([bplist _rootIndex],  0, @"rootIndex" );
    INTEXPECT([bplist _rootOffset], 8, @"offset of root object");
}

+(void)testReadInteger
{
    MPWBinaryPlist *bplist=[self bplistWithData:[self _createBinaryPlist:@(42)]];
    INTEXPECT([[bplist rootObject] intValue],  42, @"root object");
}


+testSelectors
{
    return @[ @"testRecognizesHeader",
              @"testReadTrailerAndOffsets",
              @"testReadInteger",
              ];
}

@end