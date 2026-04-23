//
//  MPWTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import "MPWTable.h"
#import "AccessorMacros.h"
#import "MPWTableColumn.h"

@implementation MPWTable
{
    NSArray <MPWTableColumn*> *columns;
    NSArray <MPWTableColumn*> *visibleColumns;
}

lazyAccessor( NSArray <MPWTableColumn*>*, columns, setColumns, computeColumns )
lazyAccessor( NSArray <MPWTableColumn*>*, visibleColumns, setVisibleColumns, computeVisibleColumns )



-(NSArray<MPWTableColumn*>*)computeColumns
{
    [NSException raise:@"unimplemnted" format:@"Subclass responsibility %@ does not implement %@",[self className],NSStringFromSelector(_cmd)];
    return nil;
}

-(NSArray<MPWTableColumn*> *)computeVisibleColumns
{
    NSMutableArray *visible = [NSMutableArray array];
    for ( MPWTableColumn *col  in self.columns) {
        if ( col.visible ) {
            [visible addObject:col];
        }
    }
    return visible;
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
