//
//  MPWUniquingQueue.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import "MPWUniquingQueue.h"

@interface MPWUniquingQueue()

@property (atomic, strong) NSMutableOrderedSet *queue;

@end

@implementation MPWUniquingQueue

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.queue = [NSMutableOrderedSet orderedSet];
    return self;
}

-(void)writeObject:(id)anObject
{
    @synchronized(self) {
        [self.queue addObject:anObject];
    }
}

-(void)forwardNext
{
    id next=nil;
    @synchronized(self) {
        next=self.queue.firstObject;
    }
    if (next) {
        FORWARD(next);
        @synchronized(self) {
            [self.queue removeObjectAtIndex:0];
        }
    }
}

-(void)drain
{
    while (self.count) {
        [self forwardNext];
    }
}

-(NSUInteger)count
{
    NSUInteger count=0;
    @synchronized (self) {
        count=self.queue.count;
    }
    return count;
}

-(void)dealloc
{
    [_queue release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWUniquingQueue(testing)

+(void)testForwardingWorks
{
    NSMutableArray *a=[NSMutableArray array];
    MPWUniquingQueue *q=[self streamWithTarget:a];
    INTEXPECT(q.count, 0, @"0 objects added");
    [q writeObject:@(1)];
    [q writeObject:@(2)];
    [q writeObject:@(3)];
    INTEXPECT(q.count, 3, @"3 objects added");
    INTEXPECT(a.count, 0, @"0 objects forwarded");
    [q drain];
    INTEXPECT(a.count, 3, @"3 objects forwarded");
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testDupsAreRejected
{
    NSMutableArray *a=[NSMutableArray array];
    MPWUniquingQueue *q=[self streamWithTarget:a];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    INTEXPECT(q.count, 1, @"3 objects tried, only 1 added");

}


+testSelectors
{
    return @[
             @"testForwardingWorks",
             @"testDupsAreRejected",
             ];
}

@end
