//
//  MPWAlias.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.10.23.
//

#import "MPWAlias.h"

@implementation MPWAlias

-value
{
    return [self.base.value value];
}

-(void)dealloc
{
    [_base release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWAlias(testing) 

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
