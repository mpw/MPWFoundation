//
//  MPWTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import "MPWTable.h"
#import "AccessorMacros.h"

@implementation MPWTable
{
    NSArray *columns;
}

lazyAccessor( NSArray *, columns, setColumns, computeColumns )


-(NSArray*)computeColumns
{
    [NSException raise:@"unimplemnted" format:@"Subclass responsibility %@ does not implement %@",[self className],NSStringFromSelector(_cmd)];
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTable(testing) 

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
