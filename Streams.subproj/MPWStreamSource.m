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
#import "MPWFilter.h"

@implementation MPWStreamSource

@synthesize  target;

-(instancetype)init {
    self=[super init];
    self.closeWhenDone=YES;
    return self;
}

-(void)readFromStreamAndWriteToTarget
{
    BOOL hasData=YES;
    //    NSLog(@"buffersize: %d",self.bufferSize);
    while ( hasData && !self.stop) {
        @autoreleasepool {
            NSData *dataToWrite=[self nextObject];
            if ( dataToWrite) {
                [(id)(self.target) writeObject:dataToWrite sender:self];
            } else {
                hasData = NO;
            }
        }
    }
    if ( self.closeWhenDone ) {
        [self close];
    }
}

-(void)closeLocal
{
    // override if needed
}

-(void)close
{
    [self closeLocal];
    [(MPWFilter*)(self.target) close];
}

-(void)run
{
    [self readFromStreamAndWriteToTarget];
}

-(void)run:(NSTimeInterval)seconds
{
    [self run];
    [self awaitResultForSeconds:seconds];
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

-(id)nextObject
{
    return nil;
}

-finalTarget
{
    if ( [self target]) {
        return [(MPWFilter*)[self target] finalTarget];
    }
    return self;
}

-(void)awaitResultForSeconds:(NSTimeInterval)seconds
{
    // is currently synchronous
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
