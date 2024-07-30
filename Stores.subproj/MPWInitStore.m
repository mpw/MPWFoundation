//
//  MPWInitStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.10.23.
//

#import "MPWInitStore.h"

@implementation MPWInitStore

-(void)at:(id<MPWIdentifying>)aReference put:(id)theObject
{
    if ( ![self at:aReference]) {
        [super at:aReference put:theObject];
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWInitStore(testing)

+(void)testDoesNotStoreNewValueOnceInitalized
{
    MPWInitStore *s=[MPWInitStore storeWithSource:[MPWDictStore store]];
    s[@"hi"] = @"firstValue";
    IDEXPECT(s[@"hi"],@"firstValue",@"not initialized, new value stored");
    s[@"hi"] = @"secondValue";
    IDEXPECT(s[@"hi"],@"firstValue",@"original value not modified");
}

+(NSArray*)testSelectors
{
   return @[
			@"testDoesNotStoreNewValueOnceInitalized",
			];
}

@end
