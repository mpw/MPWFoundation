//
//  MPWThreadSwitchStream.m
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import "MPWThreadSwitchStream.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWThreadSwitchStream

objectAccessor(NSThread*, targetThread, setTargetThread )

CONVENIENCEANDINIT(stream, WithThread:(NSThread*)aThread target:aTarget)
{
    self=[super initWithTarget:aTarget];
    [self setTargetThread:aThread];
    return self;
}

-(NSThread*)defaultThread
{
    return [NSThread mainThread];
}

-(instancetype)initWithTarget:(id)aTarget
{
    return [self initWithThread:[self defaultThread] target:aTarget];
}

-(void)forwardObjectToTarget:anObject
{
    FORWARD([anObject autorelease]);
}

-(void)writeNSObject:(id)anObject
{
    if ( [NSThread currentThread] != [self targetThread]) {
        [[self onThread:[self targetThread]] forwardObjectToTarget:[anObject retain]];
    } else {
        FORWARD(anObject);
    }
}

@end
