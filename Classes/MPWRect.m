/* MPWRect.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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

+rectWithRect:(NSRect)aRect
{
    return [[[self alloc] initWithRect:aRect] autorelease];
}

-(void)setOrigin:aPoint
{
	rect.origin=[aPoint point];
}

-(void)setMpwSize:aPoint
{
	rect.size=[aPoint asSize];
}

-(double)x
{
    return rect.origin.x;
}

-(double)y
{
    return rect.origin.y;
}

-(double)width
{
    return rect.size.width;
}

-(double)height
{
    return rect.size.height;
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

-size
{
    return [self mpwSize];
}

-(NSUInteger)count
{
    return 4;
}

-(void)getReals:(float*)reals length:(int)len
{
    if (len>=4) {
        reals[0]=rect.origin.x;
        reals[1]=rect.origin.y;
        reals[2]=rect.size.width;
        reals[3]=rect.size.height;
    }
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
#else
-description
{
    return [NSString stringWithFormat:@"%@:%p: origin=%@ extent: %@",[self class],self,[self origin],[self mpwSize
                                                                                                      ]];
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

-(double)midX
{
    return (rect.origin.x * 2 + rect.size.width)/2.0;
}

-(double)midY
{
    return (rect.origin.y * 2 + rect.size.height)/2.0;
}

-(NSPoint)center
{
    return NSMakePoint( [self midX], [self midY] );
}

-(MPWRect*)inset:(double)xInset :(double)yInset
{
    return [[self  class] rectWithRect:NSInsetRect( rect, xInset, yInset )];
}

-(MPWRect*)inset:anObject
{
    float x=0,y=0;
    if ( [anObject respondsToSelector:@selector(x)] && [anObject respondsToSelector:@selector(y)] ) {
        x=[(MPWPoint*)anObject x];
        y=[(MPWPoint*)anObject y];
    } else {
        x=[anObject doubleValue];
        y=x;
    }
    return [self inset:x :y];
}

-(NSRect)rectValue
{
    return rect;
}

@end

@implementation NSString(rectCreation)

-asRect
{
    return [MPWRect rectWithNSString:self];
}

-(NSRect)rectValue
{
    return [[self asRect] rectValue];
}

@end

#import "DebugMacros.h"

@implementation MPWRect(testing)

+(MPWRect*)_testA { return [self rectWithRect:NSMakeRect( 10,15,30,105)]; }
+(MPWRect*)_testB { return [self rectWithRect:NSMakeRect( 100,20,130,30)]; }

+(void)testMid
{
    MPWRect *a=[self _testA];
    FLOATEXPECT([a midX], 25.0, @"a midX");
    FLOATEXPECT([a midY], 67.5, @"a midY");
    MPWRect *b=[self _testB];
    FLOATEXPECT([b midX], 165.0, @"b midX");
    FLOATEXPECT([b midY], 35.0, @"b midY");
    
}

+(void)testXYWidthHeight
{
    MPWRect *a=[self _testA];
    FLOATEXPECT([a x], 10.0, @"a x");
    FLOATEXPECT([a y], 15.0, @"a y");
    FLOATEXPECT([a width], 30.0, @"a width");
    FLOATEXPECT([a height], 105.0, @"a height");
    MPWRect *b=[self _testB];
    FLOATEXPECT([b x], 100.0, @"b x");
    FLOATEXPECT([b y], 20.0, @"b y");
    FLOATEXPECT([b width], 130.0, @"b width");
    FLOATEXPECT([b height], 30.0, @"b height");
    
}


+(void)testCenter
{
    MPWRect *a=[self _testA];
    NSPoint center=[a center];

    
    FLOATEXPECT(center.x , 25.0, @"a center.x");
    FLOATEXPECT(center.y , 67.5, @"a center.y");
    MPWRect *b=[self _testB];
    center=[b center];
    FLOATEXPECT(center.x , 165.0, @"b center.x");
    FLOATEXPECT(center.y , 35.0, @"b center.y");
    
}

+(void)testInset
{
    MPWRect *a=[self _testA];
    MPWRect *insetA=[a inset:5 :4];
    FLOATEXPECT([insetA x], 15.0, @"a x");
    FLOATEXPECT([insetA y], 19.0, @"a y");
    FLOATEXPECT([insetA width], 20.0, @"a width");
    FLOATEXPECT([insetA height], 97.0, @"a height");
    
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testMid",
            @"testXYWidthHeight",
            @"testCenter",
            @"testInset",
            nil];
}

@end
