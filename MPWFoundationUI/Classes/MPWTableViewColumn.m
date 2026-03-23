//
//  MPWTableViewColumn.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 19.05.24.
//

#import "MPWTableViewColumn.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWTableViewColumn


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTableViewColumn(testing) 

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
