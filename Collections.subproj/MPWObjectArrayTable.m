//
//  MPWObjectArrayTable.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 18.03.26.
//

#import "MPWObjectArrayTable.h"

@interface MPWObjectArrayTable ()

@property (nonatomic,strong) NSMutableArray *array;

@end

@implementation MPWObjectArrayTable



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWObjectArrayTable(testing) 

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
