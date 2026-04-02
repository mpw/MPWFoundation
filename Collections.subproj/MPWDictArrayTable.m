//
//  MPWDictArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWDictArrayTable.h"

@implementation MPWDictArrayTable

-(NSArray*)computedColumns
{
    NSDictionary *sampleDict = self.firstObject;
    NSArray *keys=sampleDict.allKeys;
    NSMutableArray *columns = [NSMutableArray array];
    for ( NSString *key in keys ) {
        MPWObjectColumn *column = [MPWObjectColumn columnWithArray:self.objects key:key class:self.itemClass];
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

    MPWObjectColumn *first=columnsByKey[@"first"];
    EXPECTNOTNIL(first,@"first column");
    IDEXPECT( [first objectAtIndex:0], @"Marcel", @"first name of first row");
    IDEXPECT( [first objectAtIndex:1], @"John", @"first name of second row");
    MPWObjectColumn *last=columnsByKey[@"last"];
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
