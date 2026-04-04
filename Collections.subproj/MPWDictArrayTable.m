//
//  MPWDictArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWDictArrayTable.h"

@implementation MPWDictArrayTable


-rowKeys
{
    NSDictionary *sampleDict = self.firstObject;
    NSArray *keys=sampleDict.allKeys;
    return keys;
}


@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWDictArrayTable(testing) 

+(void)basicAccess
{
    NSArray *names = @[ @{ @"first": @"Marcel", @"last": @"Weiher" }, @{@"first": @"John", @"last": @"Doe" }];
    MPWDictArrayTable *table=[MPWDictArrayTable tableWithObjects:names];
    NSArray *columns=[table columns];
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
