//
//  MPWArrayTable.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.03.26.
//

#import "MPWArrayTable.h"

@interface MPWArrayTable ()

@property (nonatomic,strong) NSMutableArray *array;

@end

@implementation MPWArrayTable



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWArrayTable(testing) 

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
