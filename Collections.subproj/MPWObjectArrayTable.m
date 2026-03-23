//
//  MPWObjectArrayTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import "MPWObjectArrayTable.h"
#import "AccessorMacros.h"


@interface MPWObjectArrayTable ()

@property (nonatomic, strong)   NSMutableArray *objects;

@end


@implementation MPWObjectArrayTable

CONVENIENCEANDINIT( table,  WithObjects:(NSMutableArray*)newArray )
{
    self = [super init];
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

-(void)insertObject:(NSUInteger)anIndex withObject:newObject{
    [self.objects insertObject:newObject atIndex:anIndex];
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
