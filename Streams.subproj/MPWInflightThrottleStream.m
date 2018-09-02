//
//  MPWInflightThrottleStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11/26/17.
//

#import "MPWInflightThrottleStream.h"

@implementation MPWInflightThrottleStream

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.maxInflight=[self defaultMaxInflight];
    return self;
}

-(int)defaultMaxInflight
{
    return 5;
}

-(int)targetInflightCount
{
    return [[self target] inflightCount];
}

-(int)howMuchOverMaxInflight
{
    return [self targetInflightCount] - [self maxInflight];
}

-(NSTimeInterval)delay
{
    int over=[self howMuchOverMaxInflight];
    over=MAX(0,over);
    return 0.1 * (over*over);
}

-(BOOL)isOver
{
    return [self howMuchOverMaxInflight] > 0;
}

-(void)writeObject:(id)anObject sender:sender
{
    int counter=0;
    while (  [self isOver] && counter++ < 10) {
        [NSThread sleepForTimeInterval:[self delay]];
    }
    FORWARD(anObject);
}

@end

#import "DebugMacros.h"

@implementation MPWInflightThrottleStream(testing)

+(void)testDelayCompuation
{
    NSMutableArray *target=[@[]  mutableCopy];
    MPWInflightThrottleStream *s=[self streamWithTarget:target];
    EXPECTFALSE([s isOver],@"0 inflightCount should not be over");
    FLOATEXPECT([s delay],0,@"0 inflightCount, no delay");
    [target addObject:@"a"];
    [target addObject:@"a"];
    [target addObject:@"a"];
    [target addObject:@"a"];
    EXPECTFALSE([s isOver],@"4 inflightCount should not be over");
    FLOATEXPECT([s delay],0,@"4 inflightCount, no delay");
    [target addObject:@"a"];
    EXPECTFALSE([s isOver],@"5 inflightCount should not be over");
    FLOATEXPECT([s delay],0,@"5 inflightCount, no delay");
    [target addObject:@"a"];
    EXPECTTRUE([s isOver],@"6 inflightCount should be over");
    FLOATEXPECT([s delay],0.1,@"6 inflightCount, delay");
    [target addObject:@"a"];
    EXPECTTRUE([s isOver],@"7 inflightCount should be over");
    FLOATEXPECT([s delay],0.4,@"7 inflightCount, delay");
    [target addObject:@"a"];
    FLOATEXPECT([s delay],0.9,@"8 inflightCount, delay");
}


+testSelectors
{
    return @[
             @"testDelayCompuation",
             ];
}

@end

