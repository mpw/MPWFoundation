//
//  MPWDelimitedTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import "MPWDelimitedTable.h"
#import "NSBundleConveniences.h"
#import "MPWSubData.h"
#import "MPWFuture.h"

@implementation MPWDelimitedTable

objectAccessor(NSData, data, _setData)
lazyAccessor(NSArray, headerKeys, setHeaderKeys, computeHeaderKeys)
objectAccessor(NSString, fieldDelimiter, _setFieldDelimiter)
lazyAccessor(MPWIntArray, lineOffsets, setLineOffsets, computeLineOffsets)
intAccessor(eolLength, setEOLLength)
objectAccessor(MPWObjectCache, subdatas, setSubdatas)

-(void)setData:(NSData*)newData
{
    [self _setData:newData];
    bytes=[[self data] bytes];
}

-(void)setFieldDelimiter:(NSString*)newFieldDelim
{
    [self _setFieldDelimiter:newFieldDelim];
    int newLen =[newFieldDelim length];
    if ( fieldDelimiterLength> 10 ) {
        [NSException raise:@"limitcheck" format:@"field delimiter length %d exceed max 10",newLen];
    }
    fieldDelimiterLength=newLen;
    [newFieldDelim getBytes:fieldDelimiterBytes maxLength:10 usedLength:NULL encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0,10) remainingRange:NULL];
    fieldDelimiterBytes[fieldDelimiterLength]=0;
}

-(MPWIntArray*)computeLineOffsets
{
    unsigned const char *cur=bytes;
    unsigned const char *end=cur+[[self data] length];
    MPWIntArray *offsets=[MPWIntArray array];
    [offsets addInteger:0];
    if ( bytes) {
        while ( cur < end ) {
            char last = *cur++;
            if ( last == '\r' || last=='\n') {
                if ( last == '\r' && *cur=='\n') {
                    cur++;
                    [self setEOLLength:2];
                } else {
                    [self setEOLLength:1];
                }
                if ( cur < end) {
                    [offsets addInteger:cur-bytes];
                }
            }
        }
        [offsets addInteger:end-bytes];
    }
    return offsets;
}

-initWithData:(NSData*)newTableData delimiter:(NSString*)newFieldDelimiter
{
    self=[super init];
    [self setFieldDelimiter:newFieldDelimiter];
    [self setData:newTableData];
    [self setSubdatas:[[[MPWObjectCache alloc] initWithCapacity:220 class: [MPWSubData class]] autorelease]];
    [[self subdatas] setUnsafeFastAlloc:YES];
    return self;
}

-initWithTabSeparatedData:(NSData*)newTableData
{
    return [self initWithData:newTableData delimiter:@"\011"];
}

-initWithCommaSeparatedData:(NSData*)newTableData
{
    return [self initWithData:newTableData delimiter:@","];
}

-(instancetype)cloneForThrading
{
    MPWDelimitedTable *clone=[[[self class] alloc] initWithData:data delimiter:fieldDelimiter];
    [clone setLineOffsets:[self lineOffsets]];
    [clone setHeaderKeys:[self headerKeys]];
    [clone setKeysOfInterest:[self keysOfInterest]];
    return  [clone autorelease];
}

-(void)dealloc
{
    RELEASE(lineOffsets);
    RELEASE(fieldDelimiter);
    RELEASE(headerKeys);
    RELEASE(subdatas);
    RELEASE(data);
    [super dealloc];
}

-(NSUInteger)totalLineCount
{
    return [[self lineOffsets] count]-1;
}

-(NSUInteger)count
{
    return [self totalLineCount]-1;
}




-(MPWSubData*)subdataWithStart:(const char*)start length:(int)len
{
#if 1
    MPWSubData *subdata=GETOBJECT(subdatas);
    [subdata reInitWithData:data bytes:start length:len];
    return subdata;
#else
    return [[[MPWSubData alloc] initWithData:data bytes:start length:len] autorelease];
#endif
}

-(NSString*)lineAtIndex:(int)anIndex
{
    int offset=[[self lineOffsets] integerAtIndex:anIndex];
    int nextOffset=[[self lineOffsets] integerAtIndex:anIndex+1];
    int len = nextOffset-offset-[self eolLength];
    return [self subdataWithStart:(const char*)bytes+offset length:len ];
}

-(NSString*)headerLine
{
    return [self lineAtIndex:0];
}

-(NSArray*)computeHeaderKeys
{
    return [[self headerLine] componentsSeparatedByString:[self fieldDelimiter]];
}



-(long)dataAtIndex:(int)anIndex into:(id*)elements max:(int)maxElements
{
    MPWSubData *lineData=(MPWSubData*)[self lineAtIndex:anIndex+1];
    const char *start=[lineData bytes];
    const char *cur=start;
    int delimLength=[[self fieldDelimiter] length];
    const char *end =start+[lineData length];
    int elemNo=0;
    while ( cur < end && elemNo < maxElements ) {
//        const char *next=strnstr(cur, fieldDelimiterBytes, end-cur);
        const char *next=strchr(cur, fieldDelimiterBytes[0]);
        if ( !next)  {
            next=end;
        }
        if ( next ) {
            elements[ elemNo++ ] =[self subdataWithStart:cur length:next-cur ];
            cur=next+delimLength;
        } else {
            
        }
    }
    return elemNo;
}

-(NSArray*)dataAtIndex:(int)anIndex
{
    int maxElements =[[self headerKeys] count];
    id elements[ maxElements+10];
    [self dataAtIndex:anIndex into:elements max:maxElements];
    return [NSArray arrayWithObjects:elements count:maxElements];

}


-(NSDictionary*)dictionaryAtIndex:(int)anIndex
{
    return [NSDictionary
            
            dictionaryWithObjects:[self dataAtIndex:anIndex]
                                       forKeys:[self headerKeys]];
}

-(void)inRange:(NSRange)range do:(void(^)(NSDictionary* theDict, int anIndex))block
{
    int maxElements =[[self headerKeys] count];
    id elements[ maxElements+10];
    id headerArray[ maxElements+10];
    NSArray *keys=[self headerKeys];
    NSMutableDictionary *theDict=[NSMutableDictionary dictionaryWithSharedKeySet:[NSMutableDictionary sharedKeySetForKeys:keys]];
    [keys getObjects:headerArray];
    int keyCount=[keys count];
    int keyIndexes[keyCount];
    int maxElementsOfInterest=keyCount;
    if ( NO && _indexesOfInterest) {
        maxElementsOfInterest=[_indexesOfInterest count];
        for (int i=0;i<maxElementsOfInterest;i++) {
            keyIndexes[i]=[_indexesOfInterest integerAtIndex:i];
        }
    } else {
        for (int i=0;i<keyCount;i++) {
            keyIndexes[i]=i;
        }
    }
    for (int i=range.location;i<range.location + range.length;i++) {
        @autoreleasepool {
            bzero(elements, maxElements * sizeof(id));
            int numElems=[self dataAtIndex:i into:elements max:maxElements];
            numElems=MIN(numElems,keyCount);
                for (int j=0;j<maxElementsOfInterest;j++) {
                //            NSLog(@"row:%d column: %d",i,j);
                //            NSLog(@"key: %@",headerArray[j]);
                //            NSLog(@"value: %@",elements[j]);
                    id elem=elements[keyIndexes[j]];
                    if ( elem ) {
                        [theDict setObject:elem forKey:headerArray[keyIndexes[j]]];
                    }
                }
            block( theDict,i);
//            [theDict removeAllObjects];
        }
    }
    
}

-(void)do:(void(^)(NSDictionary* theDict, int anIndex))block
{
    [self inRange:NSMakeRange(0, [self count]) do:block];
}

-(id)inRangeWithDummResult:(NSRange)range do:(void(^)(NSDictionary* theDict, int anIndex))block
{
//    NSLog(@"start inRange: (%d,%d)",range.location,range.length);
    [self inRange:range do:block];
//    NSLog(@"done inRange: (%d,%d)",range.location,range.length);
    return @"dummresult";
}

objectAccessor(NSArray, keysOfInterest , _setKeysOfInterest)
objectAccessor(MPWIntArray, _indexesOfInterest , _setIndexesOfInterest)

-(void)setKeysOfInterest:(NSArray*)keys
{
    [self _setKeysOfInterest:keys];
    MPWIntArray *newIndexes=[MPWIntArray array];
    for ( NSString *key in keys) {
        [newIndexes addInteger:[[self headerKeys] indexOfObject:key]];
    }
    [self _setIndexesOfInterest:newIndexes];
}


-(void)pardo:(void(^)(NSDictionary* theDict, int anIndex))block
{
    int numParts=4;
    int partLen=[self count]/numParts + 1;
    NSMutableArray *dummyResults=[NSMutableArray array];
    for (int i=0;i<[self count];i+=partLen) {
        int thisPartLen=MIN( partLen, [self count]-i-1);
        MPWDelimitedTable *threadClone=[self cloneForThrading];
        
        [dummyResults addObject:[[threadClone future] inRangeWithDummResult:NSMakeRange(i, thisPartLen) do:Block_copy(block)   ]];
    }
    for (NSString *dummy in dummyResults) {
        [dummy stringByAppendingString:@","];
    }
}


-(NSArray*)inRange:(NSRange)r collect:(id(^)(id theDict))block
{
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:[self count]];
    [self inRange:r do:^(NSDictionary* theDict, int anIndex){
        id obj= block(theDict);
        if (obj) {
            [array addObject:obj];
        }
    }];
    return array;
}

-(NSArray*)collect:(id(^)(id theDict))block
{
    return [self inRange:NSMakeRange(0, [self count]) collect:block];
}

-(NSArray*)parcollect:(id(^)(id theDict))block
{
    int numParts=4;
    int partLen=[self count]/numParts + 1;
    NSMutableArray *partialResults=[NSMutableArray array];
    for (int i=0;i<[self count];i+=partLen) {
        int thisPartLen=MIN( partLen, [self count]-i-1);
        MPWDelimitedTable *threadClone=[self cloneForThrading];
        
        NSArray *partialResult=[[threadClone future] inRange:NSMakeRange(i, thisPartLen) collect: block ];
        [partialResults addObject:partialResult];
    }
    NSMutableArray *results=[NSMutableArray array];
    for (NSArray *temp in partialResults) {
        [results addObjectsFromArray:temp];
    }
    return results;
}

@end

#import "DebugMacros.h"

@implementation MPWDelimitedTable(testing)



+_testTable
{
    NSData *tableData=[self resourceWithName:@"first4" type:@"tabdelim"];
    MPWDelimitedTable *table=[[[self alloc] initWithTabSeparatedData:tableData] autorelease];
    return table;
}

+_testCSVTable
{
    NSData *tableData=[self resourceWithName:@"archiving-times-and-sizes" type:@"csv"];
    MPWDelimitedTable *table=[[[self alloc] initWithCommaSeparatedData:tableData] autorelease];
    return table;
}

+(void)testGetNumberOfLines
{
    MPWDelimitedTable *table=[self _testTable];
    INTEXPECT([table totalLineCount], 4, @"total lines");
    INTEXPECT([table count], 3, @"data lines");
}

+(void)testHeaderKeys
{
    NSArray *expectedKeys=@[
                            @"VD",
                            @"ID",
                            @"BF",
                            @"LK",
                            @"OK",
                            @"RN",
                            @"RZ",
                            @"ZT",
                            @"NS",
                            @"VY",
                            @"TN",
                            @"TA",
                            @"NA",
                            @"VN",
                            @"TI",
                            @"VW",
                            @"NZ",
                            @"SZ",
                            @"BG",
                            @"VB2",
                            @"NA2",
                            @"VN2",
                            @"TI2",
                            @"VW2",
                            @"HZ2",
                            @"SZ2",
                            @"BG2",
                            @"VB3",
                            @"NA3",
                            @"VN3",
                            @"TI3",
                            @"VW3",
                            @"HZ3",
                            @"SZ3",
                            @"BG3",
                            @"GN",
                            @"GTN",
                            @"GD",
                            @"ST",
                            @"HN",
                            @"HZ",
                            @"PLZ",
                            @"PO",
                            @"GV",
                            @"GB",
                            @"PKZ",
                            @"DMU",
                            @"LKMU",
                            @"OKMU",
                            @"RNMU",
                            @"ZTMU",
                            @"VDMU",
                            @"LZMU",
                            @"OKRU",
                            @"RNRU",
                            @"VYRU",
                            @"ZTRU",
                            @"NSRU",
                            @"NUAK",
                            @"NUPM",
                            @"NUEM",
                            @"RUVO",
                            @"VYVO",
                            @"RUAZ",
                            @"SEGD",
                            @"SN",
                            @"NX",
                            @"BGA",
                            @"F1",
                            @"F2",
                            @"F3",
                            @"F4",
                            @"F5",
                            @"BN",
                            @"BA",
                            @"HS",
                            @"LI",
                            @"IV",
                            @"VI",
                            @"NI",
                            @"NETZ",
                            @"AA1",
                            @"AA2",
                            @"AA3",
                            @"EX",
                            @"VX",
                            @"SX",
                            @"FD",
                            @"DW",
                            @"ETV1",
                            @"ETV2",
                            @"ETN1",
                            @"ETN2",
                            @"ZA",
                            @"ASA",
                            @"STT",
                            @"KT",
                            @"KC",
                            @"PG",
                            @"OD",
                            @"GDK",
                            @"LN",
                            @"KZB",
                            @"X_WGS84",
                            @"Y_WGS84",
                            @"X_LCC",
                            @"Y_LCC",
                            @"STADTTEIL",
                            @"QKZ",
                            @"LIEFERGRUND",
                            @"WIDERGEO",
                            @"SO",
                            @"SOA",
                            @"SOB",
                            @"HEUNTER",
                            @"ANZNRNEU",
                            @"ANZHOEHE",
                            @"ANZBREITE",
                            @"GEBIET",
                            @"GRAFIK",
                            @"ZBA",
                            @"ANKDNR",
                            @"ANARTA",
                            @"ANZNRALT",
                            @"BAAP_ID",
                            @"BVSE_ID",
                            @"PROKOM_ID",
                            @"PROKOM_LI",
                            @"PROKOM_VI",
                            @"PROKOM_NI",
                            @"PROKOM_IV",
                            @"PROKOM_POSITION",
                            @"PROKOM_MASTER_ID" ];

    MPWDelimitedTable *table=[self _testTable];
    NSArray *keys=[table headerKeys];
    INTEXPECT([keys count], 133, @"number of keys");
    IDEXPECT(keys, expectedKeys, @"keys");
}

+(void)testDictionary
{
    MPWDelimitedTable *table=[self _testTable];
    NSDictionary *dict=[table dictionaryAtIndex:2];
    IDEXPECT([dict objectForKey:@"ID"], @"213596507", @"ID");
    IDEXPECT([dict objectForKey:@"NA"], @"Ehinger-Schwarz GmbH & Co KG", @"NA");
}

+(void)testCSVTable
{
    MPWDelimitedTable *table=[self _testCSVTable];
    INTEXPECT([table totalLineCount], 18, @"total lines");
    INTEXPECT([table count], 17, @"data lines");
    NSArray *keys=[table headerKeys];
    NSArray *expectedKeys=@[     @"",
                                 @"serialize",
                                 @"deserialize",
                                 @"size (MB)",
                                 @"compressed size (MB)",
                                 @"raw peak memory (MB)",
                                 @"peak overhead  (MB)",
                                 @"% time",
                                 @"% space",
                                 @"deserialize - object creation",
                                 ];
    

    
    IDEXPECT(keys, expectedKeys, @"header keys");
    NSDictionary *dict=[table dictionaryAtIndex:2];
    IDEXPECT([dict objectForKey:@""], @"JSON", @"label");
    IDEXPECT([dict objectForKey:@"serialize"], @"2.39", @"time");
}

+testSelectors
{
    return @[
             @"testGetNumberOfLines",
             @"testHeaderKeys",
             @"testDictionary",
             @"testCSVTable",
             ];
}

@end