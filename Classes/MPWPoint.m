/* MPWPoint.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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


#import "MPWPoint.h"
#import "MPWObjectCache.h"
#import "MPWRect.h"
#import "DebugMacros.h"
#include <objc/runtime.h>

@implementation MPWPoint
/*"
   An object level point abstraction, primarily for use of points with WebScript.
"*/
scalarAccessor( NSPoint, point, setPoint )

-(NSSize)asSize
{
    NSSize size={[self point].x , [self point].y};
    return size;
}

-(NSPoint)pointValue
{
    return [self point];
}

-(const char*)objCType
{
    return @encode(NSPoint);
}

-(BOOL)isKindOfClass:(Class)aClass
{
    NSLog(@"%@ isKindOFClass: %@",[self class],aClass);
    return [super isKindOfClass:aClass];
}

-initWithPoint:(NSPoint)aPoint
{
    self = [super init];
    [self setPoint:aPoint];
    return self;
}


-(double)x
{
    return point.x;
}

-(double)y
{
    return point.y;
}

+zero
{
    return [self pointWithNSPoint:(NSPoint){0,0 }];
}

CACHING_ALLOC( _mpwPoint, 20, NO )

+_mpwPoint1
{
    return [[[self alloc] init] autorelease];
}

+pointWithNSPoint:(NSPoint)aPoint
{
    id newPoint = [self _mpwPoint];
    [newPoint setPoint:aPoint];
    return newPoint;
}

+pointWithNSSize:(NSSize)size
{
    NSPoint p={
        size.width,size.height
    };
    return [self pointWithNSPoint:p];
}

+pointWithX:(float)x y:(float)y
{
    NSPoint p={
        x,y
    };
    return [self pointWithNSPoint:p];
}
#if ! TARGET_OS_IPHONE
+pointWithNSString:(NSString*)string
{
    return [self pointWithNSPoint:NSPointFromString(string)];
}

-(NSString*)description
{
    return NSStringFromPoint( [self point] );
}
#else
-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: x=%g y=%g",[self class],self,point.x,point.y];
}
#endif
-asPoint
{
    return self;
}
-(MPWRect*)extent:otherPoint
{
	NSPoint origin=[self point];
	NSPoint extent=[otherPoint point];
	return [[[MPWRect alloc] initWithRect:NSMakeRect(origin.x,origin.y,extent.x,extent.y)] autorelease];
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
    encodeVar( aCoder, point );
}

-initWithCoder:(NSCoder*)aCoder
{
    decodeVar( aCoder, point );
    return self;
}


#define pointArithmetic( methodName, operation )\
-methodName:aPoint\
{\
	NSPoint otherPoint=NSMakePoint(0,0);\
    if ( [aPoint respondsToSelector:@selector(point)] ) { otherPoint=[aPoint point]; } \
    else { otherPoint.x = [(NSNumber*)aPoint doubleValue]; otherPoint.y = otherPoint.x;  }  \
	return [object_getClass(self) pointWithX:otherPoint.x operation point.x y:otherPoint.y operation point.y];\
}

pointArithmetic( mulPoint, * )
pointArithmetic( reverseDivPoint, / )
pointArithmetic( addPoint, + )
pointArithmetic( reverseSubPoint, - )

-add:somethingElse
{
	return [somethingElse addPoint:self];
}

-mul:somethingElse
{
	return [somethingElse mulPoint:self];
}
-sub:somethingElse
{
	return [somethingElse reverseSubPoint:self];
}

-div:somethingElse
{
	return [somethingElse reverseDivPoint:self];
}

-(float)distance:(MPWPoint*)otherPoint
{
    double dx=[otherPoint x] - [self x];
    double dy=[otherPoint y] - [self y];
    return sqrt( dx*dx + dy*dy);
}

-(void)getReals:(float*)reals length:(int)len
{
    if (len>0) {
        reals[0]=point.x;
        if ( len>1) {
            reals[1]=point.y;
        }
    }
}

-(NSUInteger)count
{
    return 2;
}

@end


@implementation NSString(pointCreation)

-asPoint
{
    return [MPWPoint pointWithNSString:self];
}

-(NSPoint)point
{
    return [[self asPoint] point];
}

-(NSSize)asSize
{
    return [[self asPoint] asSize];
}

@end

@implementation NSNumber(pointCreationAndArithmetic)

-pointWith:otherNumber
{
	return [[[MPWPoint alloc] initWithPoint:NSMakePoint([self floatValue],[otherNumber floatValue])] autorelease];
}

#define reversePointNumberArithmetic( op )\
-op:somethingElse {  return [[MPWPoint pointWithX:[self doubleValue] y:[self doubleValue]] op:somethingElse]; }\

reversePointNumberArithmetic( mulPoint )
reversePointNumberArithmetic( reverseDivPoint)
reversePointNumberArithmetic( addPoint )
reversePointNumberArithmetic( reverseSubPoint )



@end

@implementation MPWPoint(testing)

+(void)testPointArithmetic
{
	id point1 = [self pointWithX:20 y:30];
	id point2 = [self pointWithX:4 y:3];
	id mulResult,addResult,subResult,divResult;
	
	mulResult = [point1 mul:point2];
	divResult = [point1 div:point2];
	addResult = [point1 add:point2];
	subResult = [point1 sub:point2];
	FLOATEXPECT([mulResult x], 80.0, @"multiply x");
	FLOATEXPECT([mulResult y], 90.0, @"multiply y");
	FLOATEXPECT([addResult x], 24.0, @"add x");
	FLOATEXPECT([addResult y], 33.0, @"add y");
	FLOATEXPECT([subResult x], 16.0, @"sub x");
	FLOATEXPECT([subResult y], 27.0, @"add y");
	FLOATEXPECT([divResult x], 5.0, @"divide x");
	FLOATEXPECT([divResult y], 10.0, @"divide y");
}

+(void)testPointNumberArithmetic
{
	id point1 = [self pointWithX:20 y:30];
    id number = [NSNumber numberWithInt:2];
	id mulResult,addResult,subResult,divResult;
 
	mulResult = [point1 mul:number];
	divResult = [point1 div:number];
	addResult = [point1 add:number];
	subResult = [point1 sub:number];
	FLOATEXPECT([mulResult x], 40.0, @"multiply x");
	FLOATEXPECT([mulResult y], 60.0, @"multiply y");
	FLOATEXPECT([addResult x], 22.0, @"add x");
	FLOATEXPECT([addResult y], 32.0, @"add y");
	FLOATEXPECT([subResult x], 18.0, @"sub x");
	FLOATEXPECT([subResult y], 28.0, @"add y");
	FLOATEXPECT([divResult x], 10.0, @"divide x");
	FLOATEXPECT([divResult y], 15.0, @"divide y");
}

+(void)testDistance
{
	id point1 = [self pointWithX:20 y:30];
	id point2 = [self pointWithX:4 y:3];
    INTEXPECT((int)([point1 distance:point2]*10000), 313847, @"distance point1 <-> point2 * 1000");
    FLOATEXPECT([point1 distance:point1], 0.0, @"point1 point2")
}

+(void)testGetReals
{
	id point1 = [self pointWithX:20 y:30];
	id point2 = [self pointWithX:4 y:3];
    float reals[2];
    [point1  getReals:reals length:2];
    FLOATEXPECT(reals[0], 20.0, @"got x into real[0]");
    FLOATEXPECT(reals[1], 30.0, @"got y into real[1]");
    [point2  getReals:reals length:2];
    FLOATEXPECT(reals[0], 4.0, @"got x into real[0]");
    FLOATEXPECT(reals[1], 3.0, @"got y into real[1]");

}

+(void)testCount
{
	id point1 = [self pointWithX:20 y:30];
    INTEXPECT([point1 count], 2, @"always 2");
}

+(void)testPointValue
{
	id point1 = [self pointWithX:20 y:30];
    NSPoint theNSPoint=[point1 pointValue];
    FLOATEXPECTTOLERANCE(theNSPoint.x, 20, 0.001, @"x");
    FLOATEXPECTTOLERANCE(theNSPoint.y, 30, 0.001, @"y");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
            @"testPointArithmetic",
            @"testPointNumberArithmetic",
            @"testDistance",
            @"testGetReals",
            @"testCount",
            @"testPointValue",
		nil];
}

@end

