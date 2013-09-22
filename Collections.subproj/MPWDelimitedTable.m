//
//  MPWDelimitedTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import "MPWDelimitedTable.h"
#import "NSBundleConveniences.h"

@implementation MPWDelimitedTable

objectAccessor(NSArray, lines, setLines)

-(NSString*)lineDelimiter
{
    return @"\r\n";
}

-(NSString*)fieldDelimiter
{
    return @"\011";
}

-(void)setLinesFromData:(NSData*)newTableData
{
    NSString *s=[[[NSString alloc] initWithData:newTableData encoding:NSASCIIStringEncoding] autorelease];
    [self setLines:[s componentsSeparatedByString:[self lineDelimiter]]];
    if ( [[lines lastObject] length] < 2) {
        [self setLines:[[self lines] subarrayWithRange:NSMakeRange(0, [lines count]-1)]];
    }
}

-initWithData:(NSData*)newTableData
{
    self=[super init];
    [self setLinesFromData:newTableData];
    return self;
}

-(void)dealloc
{
    RELEASE(lines);
    [super dealloc];
}

-(int)totalLines
{
    return [lines count];
}

-(int)dataLines
{
    return [self totalLines]-1;
}

-(NSString*)headerLine
{
    return [lines objectAtIndex:0];
}

-(NSArray*)headerKeys
{
    return [[self headerLine] componentsSeparatedByString:[self fieldDelimiter]];
}

-(NSArray*)dataAtIndex:(int)anIndex
{
    return [[lines objectAtIndex:anIndex+1] componentsSeparatedByString:[self fieldDelimiter]];
}

-(NSDictionary*)dictionaryAtIndex:(int)anIndex
{
    return [NSDictionary dictionaryWithObjects:[self dataAtIndex:anIndex]
                                       forKeys:[self headerKeys]];
}

@end

#import "DebugMacros.h"

@implementation MPWDelimitedTable(testing)

+_testTable
{
    NSData *tableData=[self resourceWithName:@"first4" type:@"tabdelim"];
    MPWDelimitedTable *table=[[[self alloc] initWithData:tableData] autorelease];
    return table;
}

+(void)testGetNumberOfLines
{
    MPWDelimitedTable *table=[self _testTable];
    INTEXPECT([table totalLines], 4, @"total lines");
    INTEXPECT([table dataLines], 3, @"data lines");
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

+testSelectors
{
    return @[
             @"testGetNumberOfLines",
             @"testHeaderKeys",
             @"testDictionary",
             ];
}

@end