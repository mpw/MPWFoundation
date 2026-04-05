//
//  MPWObjectArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWObjectArrayTable.h"
#import "AccessorMacros.h"
#import "MPWPropertyBinding.h"
#import "MPWStructureDefinition.h"
#import "MPWVariableDefinition.h"

@interface MPWObjectArrayTable ()

@property (nonatomic, strong)   NSMutableArray *objects;
@property (nonatomic, assign)   Class itemClass;

@end



@implementation MPWObjectArrayTable
{
    MPWStructureDefinition *itemStructure;
}


CONVENIENCEANDINIT( table,  WithClass:(Class)newClass )
{
    self=[super init];
    self.itemClass = newClass;
    return self;
}


CONVENIENCEANDINIT( table,  WithObjects:(NSMutableArray*)newArray )
{
    self = [self initWithClass:[newArray.firstObject class]];
    self.objects = newArray;
    return self;
}

-(id)objectAtIndex:(NSUInteger)anIndex
{
    return _objects[anIndex];
}

-(id)objectAtIndexedSubscript:(NSUInteger)anIndex
{
    return _objects[anIndex];
}

-(void)setObject:anObject atIndexedSubscript:(NSUInteger)anIndex
{
     [_objects setObject:anObject atIndexedSubscript:anIndex];
}

lazyAccessor(MPWStructureDefinition*, itemStructure, setItemStructure, computeItemStructure )

-(MPWStructureDefinition*)computeItemStructure
{
    return [self.itemClass structure];
}

-(NSArray*)rowKeys
{
    return [[[[self itemStructure] fields] collect] name];
}

-(NSArray*)computeColumns
{
    NSMutableArray *columns = [NSMutableArray array];
    for ( MPWVariableDefinition *def in [[self itemStructure] fields] ){
        NSString *key=def.name;
        if ( [key hasPrefix:@"_"]) {
            key=[key substringFromIndex:1];
        }
        MPWObjectColumn *column = [MPWObjectColumn columnWithArray:self.objects key:key class:self.itemClass];
        if ( def.operations ==  0) {
            column.editable = NO;
        }
        [columns addObject:column];
    }
    return columns;
}



-(NSUInteger)count
{
    return _objects.count;
}

-firstObject
{
    return _objects.firstObject;
}

-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:newObject{
    [self.objects replaceObjectAtIndex:anIndex withObject:newObject];
}

-(void)insertObject:newObject  atIndex:(NSUInteger)anIndex {
    [self.objects insertObject:newObject atIndex:anIndex];
}

-(void)removeObjectAtIndex:(NSUInteger)anIndex {
    [self.objects removeObjectAtIndex:anIndex];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: objects: %@>",[self className],self,self.objects];
}

-(void)dealloc
{
    [_objects release];
    [super dealloc];
}

@end


@interface MPWObjectColumn ()



@end

@implementation MPWObjectColumn

CONVENIENCEANDINIT(column, WithArray:(NSArray*)anArray key:(NSString*)newKey  class:(Class)itemClass)
{
    self=[super init];
    self.objects=anArray;
    self.key=newKey;
    self.binding = [MPWPropertyBinding valueForName:newKey];
    [self.binding bindToClass:itemClass];
    return self;
}

-(NSUInteger)count
{
    return _objects.count;
}

-(id)objectAtIndex:(NSUInteger)anIndex
{
    return [_binding valueForTarget:_objects[anIndex]];
}

-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:newObject
{
    [_binding setValue:newObject forTarget:_objects[anIndex]];
}



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




@implementation MPWObjectColumn(testing)


+(void)testBasicAccess
{
    NSArray *names = @[ @{ @"first": @"Marcel", @"last": @"Weiher" }, @{@"first": @"John", @"last": @"Doe" }];
    MPWObjectColumn *first=[MPWObjectColumn columnWithArray:names key:@"first" class:[names.firstObject class]];
    IDEXPECT( [first objectAtIndex:0], @"Marcel", @"first name of first row");
    IDEXPECT( [first objectAtIndex:1], @"John", @"first name of second row");
    MPWObjectColumn *last=[MPWObjectColumn columnWithArray:names key:@"last" class:[names.firstObject class]];
    IDEXPECT( [last objectAtIndex:0], @"Weiher", @"last name of first row");
    IDEXPECT( [last objectAtIndex:1], @"Doe", @"last name of second row");
}

+(NSArray*)testSelectors
{
    return @[
            @"testBasicAccess",
    ];
}

@end
