//
//  MPWArrowTable.m
//  MPWArrow
//
//  Created by Marcel Weiher on 19.03.26.
//

#import "MPWArrowTable.h"

@implementation MPWArrowTable

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWArrowTable(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
