//
//  MPWStreamSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/12/17.
//
//

#import "MPWStreamSource.h"
#import <MPWWriteStream.h>
#import "MPWBlockTargetStream.h"


@implementation MPWStreamSource

@synthesize  target;

-(void)run
{
    ;
}
-(void)setFinalTarget:newTarget
{
//    NSLog(@"setFinalTarget: %@",newTarget);
    if ( [self target] && [[self target] respondsToSelector:@selector(setFinalTarget:)]) {
//        NSLog(@"target %@ has a finalTarget",[self target]);
        [(MPWWriteStream*)[self target] setFinalTarget:newTarget];
    } else {
//        NSLog(@"target %@ does not have finalTarget",[self target]);
        [self setTarget:newTarget];
    }
}

-finalTarget
{
    if ( [self target]) {
        return [[self target] finalTarget];
    }
    return self;
}

-(void)awaitResultForSeconds:(NSTimeInterval)seconds
{
    // is current synchronous
}


-(void)do:aBlock
{
    [self setFinalTarget:[MPWBlockTargetStream streamWithBlock:aBlock]];
    [self run];
}

-(void)runInThread
{
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}


-(void)dealloc
{
    [target release];
    [super dealloc];
}

@end
