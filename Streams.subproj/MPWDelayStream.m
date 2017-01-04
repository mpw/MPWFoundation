//
//  MPWDelayStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14/11/2016.
//
//

#import "MPWDelayStream.h"
#import "NSThreadInterThreadMessaging.h"


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
            [self.target writeObject:anObject sender:sender];
        } else {
            [[self.target afterDelay:relativeDelay] writeObject:anObject sender:sender];
        }
    } else {
        [self.target writeObject:anObject sender:sender];
    }
}


-(void)writeObject:(id)anObject
{
    [self writeObject:anObject sender:nil];
}


@end

#import "DebugMacros.h"

@implementation MPWDelayStream(testing)


+(void)testTimePassesWithDelayActive
{
    NSTimeInterval toDelay=0.005;
    MPWDelayStream *delayer=[self stream];
    delayer.relativeDelay=toDelay;
    NSTimeInterval before=[NSDate timeIntervalSinceReferenceDate];
    [delayer writeObject:@"hello"];
    NSTimeInterval after=[NSDate timeIntervalSinceReferenceDate];
    EXPECTTRUE( after-before > toDelay, @"should have delayed at least 5ms");
    EXPECTTRUE( after-before < (toDelay*10), @"should have delayed at most 50ms");
    IDEXPECT( [delayer.target firstObject], @"hello" , @"did write the object");
    
}


+testSelectors
{
    return @[
            @"testTimePassesWithDelayActive",
             ];
}

@end
