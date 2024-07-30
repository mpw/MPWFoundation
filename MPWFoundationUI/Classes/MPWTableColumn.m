//
//  MPWTableColumn.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 19.05.24.
//

#import "MPWTableColumn.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWTableColumn

-(id)valueForTarget:(id)anObject
{
    return [self.binding valueForTarget:anObject];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTableColumn(testing) 

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
