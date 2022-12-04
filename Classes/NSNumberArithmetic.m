//
//  NSNumberArithmetic.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "NSNumberArithmetic.h"
#import "MPWObject.h"
#import "MPWRect.h"

NSNumber* MPWCreateInteger( long theInteger )
{
    return [NSNumber numberWithLong:theInteger];
}


@implementation NSNumber(Arithmetic)


-(MPWPoint*)asPoint
{
    double v=[self doubleValue];
    return [MPWPoint pointWithX:v y:v];
}

-(MPWRect*)asRect
{
    return [[self asPoint] asRect];
}

-bitOr:other
{
    return [NSNumber numberWithLong:[self longValue] | [other longValue]];
}

-bitAnd:other
{
    return [NSNumber numberWithLong:[self longValue] & [other longValue]];
}

-bitXor:other
{
    return [NSNumber numberWithLong:[self longValue] ^ [other longValue]];
}

-pipe:other
{
     return [self bitOr:other];
}

-or:other
{
    return [self boolValue] || [other boolValue] ? @true : @false;
}

-and:other
{
    return [self boolValue] && [other boolValue] ? @true : @false;
}

-xor:other
{
    return [self boolValue] ^ [other boolValue] ? @true : @false;
}

#define defineArithOp( opName, op ) \
-opName:other {\
	const char *type1=[self objCType];\
        const char *type2=[other objCType];\
            if ( type1 && type2 && *type1=='i' && *type2=='i' ) {\
                return [NSNumber numberWithInt:[self intValue] op [other intValue]];\
            } else {\
                return [NSNumber numberWithDouble:[self doubleValue] op [other doubleValue]];\
            }\
}\

-mod:other
{
    int otherInt=[other intValue];
    if ( otherInt != 0) {
        return [NSNumber numberWithInt:[self intValue] % otherInt];
    } else {
        [NSException raise:@"division by zero" format:@"arithmetic exception dividing %@ by 0",self];
        return 0;
    }
}

-(NSNumber*)interestPercent:(NSNumber*)interest overYears:(NSNumber*)years
{
    double factor=interest.doubleValue / 100.0 + 1.0;
    double start=self.doubleValue;
    int numYears=years.intValue;
    for (int i=0;i<numYears;i++) {
        start*=factor;
    }
    return @(start);
}

defineArithOp( add, + )
defineArithOp( mul, * )
defineArithOp( sub, - )
defineArithOp( div, / )

-squared
{
    return [self mul:self];
}

-(BOOL)isLessThan:other
{
    return [self compare:other] < 0;
}

-(BOOL)isGreaterThan:other
{
    return [self compare:other] > 0;
}

-not
{
    if ( [self boolValue]  ) {
        return [NSNumber numberWithBool:false];
    } else {
        return [NSNumber numberWithBool:true];
    }
}

-(instancetype)rounded
{
    const char *type=[self objCType];
    if ( type && ( type[0]=='f' || type[0] == 'd')) {
        return @((long)round([self doubleValue]));
    }
    return self;
}

-negated
{
	const char *type1=[self objCType];
    if ( type1 && *type1 == 'i' ){
        return [NSNumber numberWithInt:-[self intValue]];
    } else {
        return [NSNumber numberWithDouble:-[self doubleValue]];
    }
}

#ifndef GS_API_LATEST

-(NSNumber*)random
{
    return [NSNumber numberWithInteger:arc4random_uniform( [self intValue])];
}

#endif

-(double)sin
{
    return sin([self doubleValue] * M_PI/180.0);
}


-(double)cos
{
    return cos([self doubleValue] * M_PI/180.0);
}

-(double)pow:(double)otherNumber
{
    return pow( [self doubleValue], otherNumber );
}

-(double)sqrt
{
    return sqrt([self doubleValue]);
}

-(double)log10
{
    return log10([self doubleValue]);
}

-(double)log
{
    return log([self doubleValue]);
}

-(double)raisedTo:(double)other
{
    return pow([self doubleValue],other);
}

-(NSString *)stringWithFormat:(NSString*)formatString
{
    NSNumberFormatter *f=[[[NSNumberFormatter alloc] init] autorelease];
    [f setPositiveFormat:formatString];
    return [f stringFromNumber:self];
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

static int fib( int n) {
    if ( n <= 1 ) {
        return n;
    } else {
        return fib(n-1) + fib(n-2);
    }
}

-fib
{
    return [NSNumber numberWithInt:fib([self intValue])];
    
}


-fastfib
{
    int c;
    int n=[self intValue];
    int first=0,second=1,next=0;
    for ( c = 0 ; c < n ; c++ )
    {
        if ( c <= 1 )
            next = c;
        else
        {
            next = first + second;
            first = second;
            second = next;
        }
    }
    return [NSNumber numberWithInt:next];

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

#import "DebugMacros.h"

@interface NSNumberArithmeticTests:NSObject
@end

@implementation NSNumberArithmeticTests

+(void)testNot
{
    EXPECTTRUE( [[[NSNumber numberWithBool:false] not] boolValue],@"not false");
    EXPECTFALSE( [[[NSNumber numberWithBool:true] not] boolValue],@"not true");
}

+(void)testNegated
{
    INTEXPECT( [[[NSNumber numberWithInt:3] negated] intValue],-3,@"negated 3");
    INTEXPECT( [[[NSNumber numberWithInt:-42] negated] intValue],42,@"negated -42");
}

+(void)testRaisedTo
{
    INTEXPECT( [@(2) raisedTo:3],8,@"2 raisedTo: 3");
}

+(NSArray*)testSelectors
{
    return @[
             @"testNot",
             @"testNegated",
             @"testRaisedTo",
             ];
}

@end
