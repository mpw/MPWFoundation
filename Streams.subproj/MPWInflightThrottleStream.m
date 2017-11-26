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
    return MAX(0,0.1 * over);
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
    [self.target writeObject:anObject sender:self];
}

@end
