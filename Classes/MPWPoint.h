/* MPWPoint.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/CodingAdditions.h>
#import <MPWFoundation/MPWObject.h>
#import <Foundation/Foundation.h>
#import <MPWFoundation/PhoneGeometry.h>


@class MPWRect;



@interface MPWPoint : MPWObject
{
    NSPoint	point;
}

scalarAccessor_h( NSPoint, point, setPoint )
-(NSSize)asSize;
+pointWithNSPoint:(NSPoint)aPoint;
+pointWithNSSize:(NSSize)aSize;
#if ! TARGET_OS_IPHONE
+pointWithNSString:(NSString*)string;
#endif
+(instancetype)x:(float)x y:(float)y;
+pointWithX:(float)x y:(float)y;
-(double)x;
-(double)y;
+zero;
-(MPWRect*)extent:otherPoint;
-(NSPoint)pointValue;
-(MPWRect*)asRect;

@end
@interface NSString(pointCreation)

-asPoint;
-(NSPoint)point;
-(NSSize)asSize;

@end

@interface NSNumber(pointCreation)

-pointWith:otherNumber;

@end
