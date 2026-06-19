//
//  MPWAbstractUIGenerator.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.26.
//

#import "MPWAbstractUIGenerator.h"

@implementation MPWAbstractUIGenerator


-(void)dealloc
{
    [_type2view release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWAbstractUIGenerator(testing) 

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
