//
//  MPWTCPStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 15.02.23.
//

#import "MPWTCPStore.h"
#import "MPWTCPBinding.h"

@implementation MPWTCPStore



-(MPWTCPBinding*)bindingForReference:aReference inContext:aContext
{
    return [MPWTCPBinding bindingWithReference:aReference inStore:self];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTCPStore(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
