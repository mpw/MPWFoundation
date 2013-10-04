//
//  MPWDelimitedTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWDelimitedTable : MPWObject
{
    NSData  *data;
    NSArray *headerKeys;
    NSString *fieldDelimiter;
    MPWIntArray *lineOffsets;
    int eolLength;
    char fieldDelimiterBytes[20];
    int  fieldDelimiterLength;
    MPWObjectCache *subdatas;
}

-initWithData:(NSData*)newTableData delimiter:(NSString*)newFieldDelimiter;
-initWithTabSeparatedData:(NSData*)newTableData;
-initWithCommaSeparatedData:(NSData*)newTableData;
-(NSUInteger)count;
-(NSArray*)headerKeys;
-(NSDictionary*)dictionaryAtIndex:(int)anIndex;

-(void)do:(void(^)(NSDictionary* theDict, int anIndex))block;
-(NSArray*)collect:(id(^)(id theDict))block;
//-(NSArray*)parcollect:(id(^)(id theDict))block;

@end

