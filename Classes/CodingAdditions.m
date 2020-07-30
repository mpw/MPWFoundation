/* CodingAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "CodingAdditions.h"
//#import "MPWEnumFilter.h"
#import <MPWFoundation/NSObjectFiltering.h>
#import "NSObjectAdditions.h"
#include <objc/runtime.h>

@implementation NSCoder(NamedCoding)

-(void)encodeObject:anObject withName:aName
{
    [self encodeObject:anObject];
}

-(void)encodeKey:aKey ofObject:anObject
{
	[self encodeObject:[anObject valueForKey:aKey]];
}

-decodeObjectWithName:aName
{
   return [self decodeObject]; 
}

-(void)decodeKey:aKey ofObject:anObject
{
	[anObject setValue:[self decodeObject] forKey:aKey];
}

-(void)encodeValueOfObjCType:(const char*)type at:(const void*)var withName:(const char*)name
{
    [self encodeValueOfObjCType:type at:var];
}

-(void)decodeValueOfObjCType:(const char*)type at:(void*)var withName:(const char*)name
{
    [self decodeValueOfObjCType:type at:var];
}

-(void)encodeArrayOfObjCType:(const char*)type count:(long)count at:(const void*)var withName:(const char*)name
{
    [self encodeArrayOfObjCType:type count:count at:var];
}
-(void)decodeArrayOfObjCType:(const char*)type count:(long)count at:(void*)var withName:(const char*)name
{
    [self decodeArrayOfObjCType:type count:count at:var];
}


@end

@implementation NSObject(reflectiveCoding)

-(void)encodeKeys:keys withCoder:(NSCoder*)aCoder
{
	[[aCoder do] encodeKey:[keys each] ofObject:self];
}


-decodeWithCoder:(NSCoder*)aCoder keys:keys
{
	[[aCoder do] decodeKey:[keys each] ofObject:self];
	return self;
}

+(BOOL)doReflectiveCoding
{
	return NO;
}

+(NSArray*)defaultEncodingKeys
{
	return [self allIvarNames];
}

-(NSArray*)encodingKeys
{
	return [object_getClass(self) defaultEncodingKeys];
}


-(NSArray*)theKeysToCopy
{
	return [self encodingKeys];
}

-(void)takeKey:aKey from:otherObject
{
	id value=[otherObject valueForKey:aKey];
	if ( value ) {
		[self setValue:value forKey:aKey];
	}
}

-copyReflectivelyWithZone:(NSZone*)aZone
{
	id copy = [[[self class] allocWithZone:aZone] init];
	id keys = [self theKeysToCopy];
	[[copy do] takeKey:[keys each] from:self];
	return copy;
}


@end

