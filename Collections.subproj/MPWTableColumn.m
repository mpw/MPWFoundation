//
//  MPWTableColumn.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import "MPWTableColumn.h"

@implementation MPWTableColumn

-(instancetype)init
{
    self=[super init];
    self.editable=true;
    return self;
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
