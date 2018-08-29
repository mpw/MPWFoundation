/*
	MPWAssociation.m created by marcel on Fri 13-Aug-1999 
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

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


#import "MPWAssociation.h"
#import "MPWObjectCache.h"
#import "CodingAdditions.h"


@implementation MPWAssociation

CACHING_ALLOC( association , 30, NO )

+associationWithKey:aKey value:aValue
{
    return [[self association] initWithKey:aKey value:aValue];
}
-initWithKey:aKey value:aValue
{
    self = [super init];
    [self setKey:aKey];
    [self setValue:aValue];
    return self;
}

idAccessor( key, setKey )
idAccessor( value, setValue )

-(void)dealloc
{
    [key release];
    [value release];
    [super dealloc];
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
    encodeVar( aCoder, key );
    encodeVar( aCoder, value );
}

-initWithCoder:(NSCoder*)aCoder
{
    decodeVar( aCoder, key );
    decodeVar( aCoder, value );
    return self;
}

@end

@implementation NSObject(associations)

-associateWithKey:aKey
{
    return [MPWAssociation associationWithKey:aKey value:self];
}

-associateWithValue:aValue
{
    return [MPWAssociation associationWithKey:self value:aValue]; 
}

@end
