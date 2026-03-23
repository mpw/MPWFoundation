//
//  MPWDictArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWDictArrayTable.h"
#import "MPWDictColumn.h"

@implementation MPWDictArrayTable

-(NSArray*)computedColumns
{
    NSDictionary *sampleDict = self.firstObject;
    NSArray *keys=sampleDict.allKeys;
    NSMutableArray *columns = [NSMutableArray array];
    for ( NSString *key in keys ) {
        MPWDictColumn *column = [MPWDictColumn columnWithArray:self.objects key:key];
        [columns addObject:column];
    }
    return columns;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDictArrayTable(testing) 

+(void)basicAccess
{
    NSArray *names = @[ @{ @"first": @"Marcel", @"last": @"Weiher" }, @{@"first": @"John", @"last": @"Doe" }];
    MPWDictArrayTable *table=[MPWDictArrayTable tableWithObjects:names];
    NSArray *columns=[table computedColumns];
    NSDictionary *columnsByKey=[columns dictionaryByKey:@"key"];

    MPWDictColumn *first=columnsByKey[@"first"];
    IDEXPECT( [first objectAtIndex:0], @"Marcel", @"first name of first row");
    IDEXPECT( [first objectAtIndex:1], @"John", @"first name of second row");
    MPWDictColumn *last=columnsByKey[@"last"];
    IDEXPECT( [last objectAtIndex:0], @"Weiher", @"last name of first row");
    IDEXPECT( [last objectAtIndex:1], @"Doe", @"last name of second row");
}

+(NSArray*)testSelectors
{
   return @[
			@"basicAccess",
			];
}

@end
