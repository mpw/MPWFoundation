//
//  NSNumberArithmetic.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "NSNumberArithmetic.h"
#import "MPWObject.h"


@implementation NSNumber(Arithmetic)


#define defineArithOp( opName, op ) \
-opName:other {\
	const char *type1=[self objCType];\
        const char *type2=[other objCType];\
            if ( type1 && type2 && *type1=='i' && *type2=='i' ) {\
                return [NSNumber numberWithInt:[self intValue] op [other intValue]];\
            } else {\
                return [NSNumber numberWithFloat:[self floatValue] op [other floatValue]];\
            }\
}\


defineArithOp( add, + )
defineArithOp( mul, * )
defineArithOp( sub, - )
defineArithOp( div, / )

-(BOOL)isLessThan:other
{
    return [self compare:other] < 0;
}

-(BOOL)isGreaterThan:other
{
    return [self compare:other] > 0;
}

-negated
{
	const char *type1=[self objCType];
    if ( type1 && *type1 == 'i' ){
        return [NSNumber numberWithInt:-[self intValue]];
    } else {
        return [NSNumber numberWithFloat:-[self floatValue]];
    }
}

-coerceToDecimalNumber
{
    const char *objcType=[self objCType];
    if ( *objcType == 'i' ) {
        return [NSDecimalNumber numberWithInt:[self intValue]];
    } else {
        return [NSDecimalNumber numberWithDouble:[self doubleValue]];
    }
}

+new {
	return [[self numberWithInt:0] retain];
}

-objcTypeString {
	return [NSString stringWithCString:[self objCType] encoding:NSASCIIStringEncoding];
}

@end

@implementation NSDecimalNumber(arithmetic)

-coerceToDecimalNumber
{
    return self;
}

-add:aNumber   {
    return [self decimalNumberByAdding:[aNumber coerceToDecimalNumber]];
}

-sub:aNumber   {
    return [self decimalNumberBySubtracting:[aNumber coerceToDecimalNumber]];
}

-mul:aNumber   {
    return [self decimalNumberByMultiplyingBy:[aNumber coerceToDecimalNumber]];
}

-div:aNumber   {
    return [self decimalNumberByDividingBy:[aNumber coerceToDecimalNumber]];
}

@end

#if 0

int sendMainMessageToClass( int argc, char *argv[], NSString *className , NSString *messageName) {
	id pool=[NSAutoreleasePool new];
	id obj;
	id args=[NSMutableArray array];
	int i,res;
	for (i=1;i<argc;i++) {
		[args addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
	}
	obj=[[NSClassFromString(className) new] autorelease];
	res=(NSUInteger)[obj performSelector: NSSelectorFromString(messageName) withObject:args];
	[pool release];
	return res;
}


id _dummyGetNumtest( int value ) {
	return [NSNumber numberWithInt:value];
}
#endif 