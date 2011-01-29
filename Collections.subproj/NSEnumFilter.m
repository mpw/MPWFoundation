/*
    NSEnumFilter.m created by marcel on Tue 22-Jul-1997
    Copyright (c) 1997-2006 Marcel Weiher. All rights reserved.

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


#import "NSEnumFilter.h"

@implementation NSEnumFilter


idAccessor( source, setSource )

+filterWithMessage:(SEL)f
{
    return [[[self alloc] initWithMessage:f argument:nil argument:nil] autorelease];
}

+filterWithMessage:(SEL)f argument:o1
{
    return [[[self alloc] initWithMessage:f argument:o1 argument:nil] autorelease];
}

+objectForKeyFilter:aKey
{
    return [self filterWithMessage:@selector(objectForKey:) argument:aKey];
}

-initWithMessage:(SEL)f argument:o1 argument:o2
{
    [super init];
    filterMsg=f;
    object1=[o1 retain];
    object2=[o2 retain];

    return self;
}

-doFilter:baseObject
{
    return [baseObject performSelector:filterMsg withObject:object1 withObject:object2];
}

-nextObject
{
    id result;
    do {
        if ( nil!=(result = [source nextObject])) {
            result = [self doFilter:result];
        } else {
            return nil;
        }
    } while ( result == nil );
    return result;
}

-(void)dealloc
{
    [source release];
    [object1 release];
    [object2 release];
}

@end

@implementation NSEnumerator(Filtering)

-filterWithMessage:(SEL)msg argument:arg1
{
    id newFilter=[[self class] filterWithMessage:msg argument:arg1];
    [newFilter setSource:self];
    return newFilter;
}

-filterWithMessage:(SEL)msg
{
    return [self filterWithMessage:msg argument:nil];
}

@end
