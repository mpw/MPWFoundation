/* CodingAdditions.m Copyright (c) 1998-2015 by Marcel Weiher, All Rights Reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

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

-initWithCoder:(NSCoder*)aCoder keys:keys
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
	return [self ivarNames];
}

-(NSArray*)encodingKeys
{
	return [object_getClass(self) defaultEncodingKeys];
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
	if ( [object_getClass(self) doReflectiveCoding] ) {
		[self encodeKeys:[self encodingKeys] withCoder:aCoder];
	}
}

-initWithCoder:(NSCoder*)aCoder
{
	if ( [object_getClass(self) doReflectiveCoding] ) {
		self = [self initWithCoder:aCoder keys:[self encodingKeys]];
	}
	return self;
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

