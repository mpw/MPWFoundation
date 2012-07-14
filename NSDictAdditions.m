/* NSDictAdditions.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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

-(id)at:anObject
{
    return [self objectForKey:anObject];
}

@end

@implementation NSArray(at)

-(id)at:anObject
{
    return [self objectAtIndex:[anObject intValue]];
}

@end


@implementation NSObject(at)

-(id)at:anObject
{
    return [self valueForKey:anObject];
}

@end
