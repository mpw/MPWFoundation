/* MPWRect.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/CodingAdditions.h>
#import <Foundation/Foundation.h>
#import <MPWPoint.h>




@interface MPWRect : NSObject
{
    NSRect	rect;
}

scalarAccessor_h( NSRect, rect, setRect )
+rectWithNSRect:(NSRect)aRect;
#if ! TARGET_OS_IPHONE
+rectWithNSString:(NSString*)string;
#endif
-initWithRect:(NSRect)aRect;
-origin;
-mpwSize;

-(double)x;
-(double)y;
-(double)width;
-(double)height;
-(NSRect)rectValue;



@end
@interface NSString(rectCreation)

-asRect;
-(NSRect)rectValue;

@end
