//
//  MPWObjectArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWObjectArrayTable.h"
#import "AccessorMacros.h"
#import "MPWObjectColumn.h"

@interface MPWObjectArrayTable ()

@property (nonatomic, strong)   NSMutableArray *objects;
@property (nonatomic, assign)   Class itemClass;

@end


@implementation MPWObjectArrayTable

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

-(NSArray*)computedColumns
{
    NSArray *keys=[[[self.itemClass instanceVariables] collect] name];
    keys = [keys subarrayWithRange:NSMakeRange(1, keys.count-1)];
    NSMutableArray *columns = [NSMutableArray array];
    for ( NSString *key in keys ) {
        MPWObjectColumn *column = [MPWObjectColumn columnWithArray:self.objects key:key];
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
    return [NSString stringWithFormat:@"<%@:%p: objects: %@>",self.className,self,self.objects];
}

-(void)dealloc
{
    [_objects release];
    [super dealloc];
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
