//
//  MPWInteger.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 20/3/07.
//  Copyright 2010-2012 by Marcel Weiher. All rights reserved.
//

#import "MPWInteger.h"
#import <MPWFoundation/MPWFoundation.h>
#import <objc/runtime.h>

@implementation MPWInteger


+integer:(int)newValue
{
    return [[[self alloc] initWithInteger:newValue] autorelease];
}

+numberWithInt:(int)anInt
{
	return [self integer:anInt];		//	NSNumber compatibility
}

-initWithInteger:(NSInteger)newValue
{
    self = [super init];
    intValue=newValue;
    return self;
}

-(int)intValue
{
    return intValue;
}

-(float)floatValue
{
    return (float)intValue;
}

-(void)setIntValue:(int)newInt
{
    intValue=newInt;
}

-(void)setFloatValue:(float)newFloat
{
    intValue=(int)newFloat;
}

#define defineArithOp( opName, intOpName, op ) \
-intOpName:(int)anInt {\
	return [[self class] integer:anInt op intValue];\
}\
-opName:other {\
	return [other intOpName:intValue];\
}\

defineArithOp( add, addInt,  + )
defineArithOp( mul, mulInt, * )
defineArithOp( sub, subInt, - )
defineArithOp( div, divInt, / )




-(NSString*)stringValue
{
    return [NSString stringWithFormat:@"%d",intValue];
}

-(BOOL)isEqual:otherValue
{
    return otherValue == self || ( object_getClass(self)==object_getClass(otherValue) && intValue==((MPWInteger*)otherValue)->intValue)
    || [otherValue isEqualToInteger:intValue];
}

-(BOOL)isEqualToFloat:(float)floatValue
{
    return intValue == floatValue;
}


-(NSUInteger)hash
{
    return intValue;
}

-negate
{
    intValue = -intValue;
    return self;
}

#if ! TARGET_OS_IPHONE

-(void)encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    encodeVar( coder, intValue );
}

-initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    decodeVar( coder, intValue );
   return self;
}

#endif

-(int)compare:other
{
	return intValue - [other intValue];
}


@end

@implementation NSObject(isEqualToInteger)

-(BOOL)isEqualToInteger:anInt
{
	return NO;
}


@end
