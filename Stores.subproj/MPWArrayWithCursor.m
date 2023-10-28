//
//  MPWArrayWithCursor.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.10.23.
//

#import "MPWArrayWithCursor.h"

@interface MPWArrayWithCursor()

@property (nonatomic,strong) NSMutableArray *base;

@end

@implementation MPWArrayWithCursor

-(instancetype)initWithCapacity:(NSUInteger)numItems
{
    self=[super init];
    self.base = [NSMutableArray arrayWithCapacity:numItems];
    return self;
}

-(instancetype)initWithArray:(NSMutableArray *)array
{
    self=[super init];
    self.base=array;
    return self;
}

+(instancetype)arrayWithArray:(NSArray *)array
{
    return [[[self alloc] initWithArray:array] autorelease];
}

-objectAtIndex:(unsigned long)theIndex
{
    return [self.base objectAtIndex:theIndex];
}

-(void)replaceObjectAtIndex:(unsigned long)theIndex withObject:anObject
{
    [self.base replaceObjectAtIndex:theIndex withObject:anObject];
}

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self.base insertObject:anObject atIndex:index];
}

-(unsigned long)count
{
    return self.base.count;
}

-selectedObject
{
    return [self objectAtIndex:self.offset];
}

-(id)value
{
    return [self selectedObject];
}

-(void)setValue:newValue
{
    [self replaceObjectAtIndex:self.offset withObject:newValue];
}

-at:ref
{
    if ( [ref isKindOfClass:[NSNumber class]]) {
        return [self objectAtIndex:[ref longValue]];
    } else {
        NSArray *comps=[ref pathComponents];
        id value=self;
        for (NSString *comp in comps) {
            if ( [comp isEqual:@"selectedObject"]) {
                value = [value selectedObject];
            } else {
                value = [value valueForKey:comp];
            }
        }
        return value;
    }
}

-(void)at:ref put:value
{
    NSLog(@"%@ at:%@ put:%@",self,ref,value);
    if ( [ref isKindOfClass:[NSNumber class]]) {
         [self replaceObjectAtIndex:[ref longValue] withObject:value];
    } else {
        NSArray *comps=[ref pathComponents];
        id target=self;
        for (int i=0;i<comps.count-1;i++) {
            NSString *comp=comps[i];
            if ( [comp isEqual:@"selectedObject"]) {
                target = [target selectedObject];
            } else {
                target = [target valueForKey:comp];
            }
        }
        NSLog(@"will set %@ on %@ of object %@",value,comps.lastObject,target);
        [target setValue:value forKey:comps.lastObject];
        NSLog(@"did set, obj now %@ -> %@",target,[target valueForKey:comps.lastObject]);
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWArrayWithCursor(testing) 

+(void)testBasicOffset
{
    MPWArrayWithCursor *array=[MPWArrayWithCursor arrayWithArray:@[@"first",@"second"]];
    IDEXPECT( [array value],@"first",@"element zero");
    array.offset=1;
    IDEXPECT( [array value],@"second",@"last");

}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicOffset",
			];
}

@end
