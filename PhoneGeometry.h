//
//  PhoneGeometry.h
//  LDMac
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
#define NSMakeRect  CGRectMake
#define NSMakePoint CGPointMake
#define NSMakeSize  CGSizeMake


#endif
#endif
