//
//  MPWTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import "MPWTable.h"
#import "AccessorMacros.h"
#import "MPWTableColumn.h"
#import "MPWInstanceVariableDefinition.h"

@implementation MPWTable
{
    MPWStructureDefinition *itemStructure;
    NSArray <MPWTableColumn*> *columns;
    NSArray <MPWTableColumn*> *visibleColumns;
    NSDictionary <NSString*, MPWTableColumn*> *columnsByKey;
    NSString *tableIdentifier;
}

lazyAccessor( NSArray <MPWTableColumn*>*, columns, setColumns, computeColumns )
lazyAccessor( NSArray <MPWTableColumn*>*, visibleColumns, setVisibleColumns, computeVisibleColumns )
lazyAccessor( NSDictionary* , columnsByKey, setColumnsByKey, computeColumnsByKey )
lazyAccessor(MPWStructureDefinition*, itemStructure, setItemStructure, computeItemStructure )
lazyAccessor(NSString*, tableIdentifier, setTableIdentifier, computeTableIdentifier )

-(NSDictionary <NSString*, MPWTableColumn*> *)computeColumnsByKey
{
    return [[self columns] dictionaryByKey:@"key"];
}

-(MPWTableColumn*)columnForKey:(NSString *)aKey
{
    return self.columnsByKey[aKey];
}

-(NSString*)computeTableIdentifier
{
    return [[self itemStructure] name];
}

-(MPWTableColumn*)createColumnForKey:aKey
{
    [NSException raise:@"unimplemnted" format:@"Subclass responsibility %@ does not implement %@",[self className],NSStringFromSelector(_cmd)];
    return nil;
}

-(NSArray*)computeColumns
{
    NSMutableArray *columns = [NSMutableArray array];
    for ( MPWVariableDefinition *def in [[self itemStructure] fields] ){
        NSString *key=def.name;
        if ( [key hasPrefix:@"_"]) {
            key=[key substringFromIndex:1];
        }
        MPWTableColumn *column = [self createColumnForKey:key];
        column.type = def.type;
        if ( def.operations ==  0) {
            column.editable = NO;
        }
        column.visible = def.type.visible;
        [columns addObject:column];
    }
    return columns;
}

-(void)rowsDo:(void (^)(NSNumber * _Nonnull))block
{
    [NSException raise:@"unimplemnted" format:@"Subclass responsibility %@ does not implement %@",[self className],NSStringFromSelector(_cmd)];
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
