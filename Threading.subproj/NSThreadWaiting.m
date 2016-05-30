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

+ (BOOL)sleepForTimeInterval:(NSTimeInterval)timeToWait orUnitlConditionIsMet:(NSNumber* (^)(void))conditionBlock
{
    NSTimeInterval end=[NSDate timeIntervalSinceReferenceDate] + timeToWait;
    do {
        if ( [conditionBlock() boolValue] ) {
            return YES;
        } else {
            [self sleepForTimeInterval:1.0 / CHECKS_PER_SECOND];
        }
    } while ( [NSDate timeIntervalSinceReferenceDate] < end );
    return NO;
}

@end


@implementation NSThreadWaitingTests : NSThread

+(void)testTrueIsDoneImmediately
{
    NSTimeInterval start=[NSDate timeIntervalSinceReferenceDate];
    [self sleepForTimeInterval:0.2 orUnitlConditionIsMet:^{ return @YES; }];
    NSTimeInterval end=[NSDate timeIntervalSinceReferenceDate];
    EXPECTTRUE(end-start < 0.03 , @"wait time significantly less than timeout");
}

+(void)testFalseWaitsFullTime
{
    NSTimeInterval start=[NSDate timeIntervalSinceReferenceDate];
    [self sleepForTimeInterval:0.2 orUnitlConditionIsMet:^{ return @NO; }];
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