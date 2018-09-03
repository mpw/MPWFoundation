//
//  MPWDelayStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import "MPWDelayStream.h"
#import "NSThreadInterThreadMessaging.h"

@interface MPWDelayStream()


@end

@implementation MPWDelayStream

//NSTimeInterval current=[NSDate timeIntervalSinceReferenceDate];
//NSTimeInterval relativeDelay = self.delayUntil - current;

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.synchronous=YES;
    return self;
}

-(void)writeObject:(id)anObject sender:sender
{
    NSTimeInterval relativeDelay=self.relativeDelay;
    if ( relativeDelay > 0) {
        if ( self.synchronous) {
            [NSThread sleepForTimeInterval:relativeDelay];
            [self forward:anObject];
        } else {
            [[self afterDelay:relativeDelay] forward:anObject];
        }
    } else {
        [self.target writeObject:anObject sender:sender];
    }
}


@end

#import "DebugMacros.h"

@implementation MPWDelayStream(testing)


+(void)testTimePassesWithDelayActive
{
    NSTimeInterval toDelay=0.005;
    NSMutableArray *target=[NSMutableArray array];
    MPWDelayStream *delayer=[self streamWithTarget:target];
    delayer.relativeDelay=toDelay;
    NSTimeInterval before=[NSDate timeIntervalSinceReferenceDate];
    [delayer writeObject:@"hello"];
    NSTimeInterval after=[NSDate timeIntervalSinceReferenceDate];
    EXPECTTRUE( after-before > toDelay, @"should have delayed at least 5ms");
    EXPECTTRUE( after-before < (toDelay*10), @"should have delayed at most 50ms");
    IDEXPECT( [target firstObject], @"hello" , @"did write the object");
    
}


+testSelectors
{
    return @[
            @"testTimePassesWithDelayActive",
             ];
}

@end
