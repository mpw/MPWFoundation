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
//    NSArray *lines;
    NSArray *headerKeys;
    NSString *fieldDelimiter;
    MPWIntArray *lineOffsets;
    int eolLength;
    MPWObjectCache  *subdatas;
    char fieldDelimiterBytes[20];
    int  fieldDelimiterLength;
}

-initWithData:(NSData*)newTableData delimiter:(NSString*)newFieldDelimiter;
-initWithTabSeparatedData:(NSData*)newTableData;
-initWithCommaSeparatedData:(NSData*)newTableData;
-(NSUInteger)count;
-(NSArray*)headerKeys;
-(NSDictionary*)dictionaryAtIndex:(int)anIndex;

-(void)iterateTableDictionaries:(void(^)(NSDictionary* theDict, int anIndex))block;

@end

