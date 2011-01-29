//
//  MPWFloat.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2010-2011 by Marcel Weiher. All rights reserved.
//

#import "MPWFloat.h"
#import <MPWFoundation/MPWFoundation.h>


@implementation MPWFloat

+float:(float)newValue
{
	return [[[self alloc] initWithFloat:newValue] autorelease];
}

+double:(double)newValue
{
	return [[[self alloc] initWithDouble:newValue] autorelease];
}

+numberWithFloat:(float)newValue
{
	return [self float:newValue];
}

+numberWithDouble:(double)newValue
{
	return [self double:newValue];
}

-initWithDouble:(double)newValue
{
    self = [super init];
    floatValue=newValue;
    return self;
}

-initWithFloat:(float)newValue
{
    return [self initWithDouble:(double)newValue];
}

-(float)floatValue
{
    return floatValue;
}

-(double)doubleValue
{
    return floatValue;
}

#define defineArithOp( opName, intOpName, op ) \
-intOpName:(int)anInt {\
	return [[self class] double:anInt op floatValue];\
}\
-opName:other {\
	return [[self class] double:floatValue op [other floatValue]];\
}\

defineArithOp( add , addInt,  + )
defineArithOp( mul, mulInt, * )
defineArithOp( sub, subInt, - )
defineArithOp( div, divInt, / )



-(int)intValue
{
    return (int)floatValue;
}

-(void)setIntValue:(int)newInt
{
    floatValue=(float)newInt;
}

-(void)setFloatValue:(float)newFloat
{
    floatValue=newFloat;
}

-(NSString*)stringValue
{
    return [[NSNumber numberWithDouble:floatValue] stringValue];
//    return [NSString stringWithFormat:@"%f",floatValue];
}

-(BOOL)isEqualToInteger:(int)intValue
{
    return intValue == floatValue;
}

-(BOOL)isEqual:otherValue
{
    return otherValue == self || (*(Class*)otherValue == isa && floatValue==((MPWFloat*)otherValue)->floatValue)
    || [otherValue isEqualToFloat:floatValue];
}

-negate
{
    floatValue = -floatValue;
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    encodeVar( coder, floatValue );
}

-initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    decodeVar( coder, floatValue );
   return self;
}


@end


@implementation NSObject(isEqualToFloat)

-(BOOL)isEqualToFloat:aFloat
{
	return NO;
}

@end

