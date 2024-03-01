/* NSDictAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSDictAdditions.h"

@implementation NSDictionary(Additions)
/*"
    Convenience methods for using #NSDictionary with plain C data type #float, #int, and #BOOL.
"*/

- (int)integerForKey:(NSString *)key
/*"
    Returns the #intValue of the object at #key.
"*/
{
    return [[self objectForKey:key] intValue];
}

- (float)floatForKey:(NSString *)key
/*"
    Returns the #floatValue of the object at #key.
"*/
{
    return [[self objectForKey:key] floatValue];
}

- (BOOL)boolForKey:(NSString *)key
/*"
    Returns the #intValue of the object at #key.
"*/
{
    return [[self objectForKey:key] boolValue];
}

-objectForIntKey:(int)intKey
{
	return [self objectForKey:[NSNumber numberWithInt:intKey]];
}

//-(id)at:aKey      // FIXME (maybe:  having at: as a synonym for objectForKey: interferes with at: for stores eval.)
//{
//    return [self valueForKeyPath:aKey];
//}

+(instancetype)dictionaryWithObjects:(NSArray*)sourceArray byKey:(NSString*)key
{
    NSArray *keys=[sourceArray valueForKey:key];
    return [self dictionaryWithObjects:sourceArray forKeys:keys];
}

@end
@implementation NSMutableDictionary(Additions)
/*"
    Convenience methods for using #NSMutableDictionary with plain C data type #float, #int, and #BOOL.
"*/

- (void)setInteger:(int)value forKey:(NSString *)key
/*"
    Stores the #NSNumber with the integer #value at #key.
"*/
{
    [self setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)setFloat:(float)value forKey:(NSString *)key
/*"
     Stores the #NSNumber with the float #value at #key.
"*/
{
    [self setObject:[NSNumber numberWithFloat:value] forKey:key];
}
- (void)setBool:(BOOL)value forKey:(NSString *)key
/*"
    Stores the #NSNumber with the BOOL #value at #key.
"*/
{
    [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

-(void)setObject:anObject forIntKey:(int)intKey
{
	[self setObject:anObject forKey:[NSNumber numberWithInt:intKey]];
}


-at:aKey put:anObject
{
    [self setObject:anObject forKey:aKey];
    return anObject;
}

@end

@implementation NSArray(at)

-(id)at:anIndex
{
    return [self objectAtIndex:[anIndex intValue]];
}

-at:anIndex put:anObject
{
    [NSException raise:@"invalidaccess" format:@"at:put: trying to modify an immutable array"];
    return nil;
}

@end

@implementation NSMutableArray(atput)

-at:anIndex put:anObject
{
    [self replaceObjectAtIndex:[anIndex longValue] withObject:anObject];
    return anObject;
}

@end


@implementation NSObject(at)

-(id)at:anObject
{
    return [self valueForKey:anObject];
}

-yourself
{
    return self;
}

@end

@implementation NSArray(dictionaryByKey)

-(NSDictionary*)dictionaryByKey:(NSString*)key
{
    return [NSDictionary dictionaryWithObjects:self byKey:key];
}

-(NSMutableDictionary*)mutableDictionaryByKey:(NSString*)key
{
    return [NSMutableDictionary dictionaryWithObjects:self byKey:key];
}
@end
