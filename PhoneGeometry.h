//
//  PhoneGeometry.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 11/11/10.
//  Copyright 2010-2011 Marcel Weiher. All rights reserved.
//


#if TARGET_OS_IPHONE
#ifndef PHONE_GEOMETRY
#define PHONE_GEOMETRY
#import <CoreGraphics/CoreGraphics.h>
typedef CGRect NSRect;
typedef CGPoint NSPoint;
typedef CGSize NSSize;
#define NSMakeRect          CGRectMake
#define NSMakePoint         CGPointMake
#define NSMakeSize          CGSizeMake
#define NSEqualPoints       CGPointEqualToPoint
#define NSEqualRects        CGRectEqualToRect
#define NSIntersectsRect    CGRectIntersectsRect
#define NSUnionRect         CGRectUnion
#define NSZeroRect          CGRectNull
#define NSInsetRect         CGRectInset

static inline NSString *NSStringFromRect( CGRect r ) { return [NSString stringWithFormat:@"(%g,%g - %g,%g)",r.origin.x,r.origin.y,r.size.width,r.size.height]; }
static inline NSString *NSStringFromPoint( CGPoint p ) { return [NSString stringWithFormat:@"(%g,%g)",p.x,p.y]; }
static inline NSString *NSStringFromSize( CGSize s ) { return [NSString stringWithFormat:@"(%g,%g)",s.width,s.height]; }



#endif
#endif
