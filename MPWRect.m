/* MPWRect.m Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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


#import "MPWRect.h"
#import "MPWPoint.h"

@implementation MPWRect
/*"
   An object level rectangle abstraction, primarily for use of points with WebScript.
"*/

scalarAccessor( NSRect, rect, setRect )

-initWithRect:(NSRect)aRect
{
    self = [super init];
    [self setRect:aRect];
    return self;
}

-(void)setOrigin:aPoint
{
	rect.origin=[aPoint point];
}

-(void)setMpwSize:aPoint
{
	rect.size=[aPoint asSize];
}

-origin
{
    return [MPWPoint pointWithNSPoint:rect.origin];
}

-mpwSize
{
    return [MPWPoint pointWithNSPoint:(NSPoint){
        rect.size.width,rect.size.height
    }];
}

+rectWithNSRect:(NSRect)aRect
{
    return [[[self alloc] initWithRect:aRect] autorelease];
}
#if ! TARGET_OS_IPHONE

+rectWithNSString:(NSString*)string
{
    return [self rectWithNSRect:NSRectFromString(string)];
}

-description
{
    return NSStringFromRect( [self rect] );
}
#endif
-(void)encodeWithCoder:(NSCoder*)aCoder
{
    encodeVar( aCoder, rect );
}

-initWithCoder:(NSCoder*)aCoder
{
    decodeVar( aCoder, rect );
    return self;
}

@end

@implementation NSString(rectCreation)

-asRect
{
    return [MPWRect rectWithNSString:self];
}

-(NSRect)rect
{
    return [[self asRect] rect];
}

@end

