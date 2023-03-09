//
//  NSThreadWaiting.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 30/05/16.
//
//

#import "NSThreadWaiting.h"
#import "DebugMacros.h"

@implementation NSThread(Waiting)

#define CHECKS_PER_SECOND 100

+ (BOOL)sleepForTimeInterval:(NSTimeInterval)timeToWait orUntilConditionIsMet:(NSNumber* (^)(void))conditionBlock
{
    NSTimeInterval end=[NSDate timeIntervalSinceReferenceDate] + timeToWait;
    do {
        if ( [conditionBlock() boolValue] ) {
            return YES;
        } else {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0/CHECKS_PER_SECOND]];
        }
    } while ( [NSDate timeIntervalSinceReferenceDate] < end );
    return NO;
}

+ (void)sleep:(NSNumber*)timeToWait
{
    [self sleepForTimeInterval:timeToWait.doubleValue];
}


@end

@interface NSThreadWaitingTests : NSThread
@end

@implementation NSThreadWaitingTests

+(void)testTrueIsDoneImmediately
{
    NSTimeInterval start=[NSDate timeIntervalSinceReferenceDate];
    [self sleepForTimeInterval:0.2 orUntilConditionIsMet:^{ return @YES; }];
    NSTimeInterval end=[NSDate timeIntervalSinceReferenceDate];
    EXPECTTRUE(end-start < 0.03 , @"wait time significantly less than timeout");
}

+(void)testFalseWaitsFullTime
{
    NSTimeInterval start=[NSDate timeIntervalSinceReferenceDate];
    [self sleepForTimeInterval:0.2 orUntilConditionIsMet:^{ return @NO; }];
    NSTimeInterval end=[NSDate timeIntervalSinceReferenceDate];
    EXPECTTRUE(end-start >= 0.2 , @"wait time greater than or equal timeout");
}

+testSelectors
{
    return @[
             @"testTrueIsDoneImmediately",
             @"testFalseWaitsFullTime",
             
             ];
}

@end
