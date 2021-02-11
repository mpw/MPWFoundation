//
//  MPWNameRemappingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.02.21.
//

#import "MPWNameRemappingStore.h"

@implementation MPWNameRemappingStore

-(id)at:(id<MPWReferencing>)aReference
{
    id<MPWReferencing> mapped=self.nameMap[aReference];
    if ( mapped ) {
        return [self.source at:mapped];
    } else {
        return [self.source at:aReference];
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWNameRemappingStore(testing) 

+(void)testNamesAreRemapped
{
    MPWDictStore *base=[MPWDictStore storeWithDictionary:@{ @"keyThatExists": @"value" }];
    MPWNameRemappingStore *mapper=[self storeWithSource:base];
    IDEXPECT( mapper[@"keyThatExists"],@"value",@"basic sourcing should work");
    EXPECTNIL( mapper[@"keyThatDoesntExist"],@"key that's not in base");
    mapper.nameMap = @{ @"keyThatDoesntExist" : @"keyThatExists" };
    IDEXPECT( mapper[@"keyThatDoesntExist"],@"value",@"basic sourcing should work");

    
}

+(NSArray*)testSelectors
{
   return @[
			@"testNamesAreRemapped",
			];
}

@end
