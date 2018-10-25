//
//  MPWUniquingQueue.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import "MPWQueue.h"
#import "AccessorMacros.h"

@protocol OrderedCollection<NSObject>

-(void)addObject:anObject;
-(void)removeObjectAtIndex:(NSUInteger)anIndex;
-firstObject;
-(NSUInteger)count;

@end

@interface NSMutableArray(collecting)<OrderedCollection>
@end

@interface NSOrderedSet(collecting)<OrderedCollection>
@end


@interface MPWQueue()

@property (atomic, strong) id <OrderedCollection> queue;
@property (atomic, strong) NSObject* inflight;
@property (atomic, strong) NSString* name;
@property (atomic, strong) NSThread* flusherThread;


@end

@implementation MPWQueue

CONVENIENCEANDINIT( queue, WithTarget:(id)aTarget uniquing:(BOOL)shouldUnique)
{
    self=[super initWithTarget:aTarget];
    self.queue = shouldUnique ? [NSMutableOrderedSet orderedSet] : [NSMutableArray array];
    return self;
}

-(instancetype)initWithTarget:(id)aTarget
{
    return [self initWithTarget:aTarget uniquing:NO];
}

-(void)writeObject:(id)anObject sender:aSender
{
    @synchronized(self) {
        [self.queue addObject:anObject];
    }
    if ( self.autoFlush ) {
        [self triggerDrain];
    }
}

-(void)triggerDrain
{
    if ( (self.flusherThread == nil) || ([NSThread currentThread] == self.flusherThread) ) {
        [self drain];
    } else {
        [self performSelector:@selector(drain)
                     onThread:self.flusherThread
                   withObject:nil
                waitUntilDone:NO
                        modes:@[ NSDefaultRunLoopMode ]];
    }
}

-(void)removeFirstObject
{
    @synchronized(self) {
        [self.queue removeObjectAtIndex:0];
    }
}

-(void)forwardSingleObject
{
    BOOL removeInflight=self.removeInflight;
    id next=nil;
    @synchronized(self) {
        next=self.queue.firstObject;
    }
    if (next) {
        self.inflight=next;
        if ( removeInflight ) {
            [self removeFirstObject];
        }
        @try {
            [self forward:next];
        } @finally {
            if ( !removeInflight)  {
                [self removeFirstObject];
            }
            self.inflight=nil;
        }
    }
}

-(void)drain
{
    while (self.count) {
        [self forwardSingleObject];
    }
}

-(void)flusherThreadRunLoop
{
    @autoreleasepool {
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        [loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [loop run];
    }
}

-(void)setFlusherThreadName
{
    [self.flusherThread setName:[NSString stringWithFormat:@"Queue Processing Thread %@ %p", self.name, self]];
}

-(void)createFlusherThreadIfNecessary
{
    if ( !self.flusherThread) {
        self.flusherThread = [[[NSThread alloc] initWithTarget:self selector:@selector(flusherThreadRunLoop) object:nil] autorelease];
        [self setFlusherThreadName];
        [self.flusherThread start];
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

@implementation MPWQueue(testing)

+aTestQueue {
    return [self streamWithTarget:[NSMutableArray array]];
}


+filledTestQueue {
    MPWQueue *q=[self aTestQueue];
    INTEXPECT(q.count, 0, @"0 objects added");
    [q writeObject:@(1)];
    [q writeObject:@(2)];
    [q writeObject:@(3)];
    INTEXPECT(q.count, 3, @"3 objects added");
    return q;
}

+(void)testDrainForwardsAllToTarget
{
    MPWQueue *q=[self filledTestQueue];
    NSArray *a=(NSArray*)[q target];
    INTEXPECT(a.count, 0, @"0 objects forwarded");
    [q drain];
    INTEXPECT(a.count, 3, @"3 objects forwarded");
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testTriggeringWorksSameAsDrain
{
    MPWQueue *q=[self filledTestQueue];
    NSArray *a=(NSArray*)[q target];
    [q triggerDrain];
    INTEXPECT(a.count, 3, @"3 objects forwarded");
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testDupsAreRejectedWhenUniquing
{
    NSMutableArray *a=[NSMutableArray array];
    MPWQueue *q=[[[self alloc] initWithTarget:a uniquing:YES] autorelease];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    INTEXPECT(q.count, 1, @"3 objects tried, only 1 added");

}

+(void)testAutoflushDrainsImmediately
{
    MPWQueue *q=[self aTestQueue];
    [q setAutoFlush:YES];
    NSArray *a=(NSArray*)[q target];
    [q writeObject:@(1)];
    INTEXPECT( q.count, 0 ,@"should have flushed immediately");
    IDEXPECT(a, (@[@(1)]),@"target");
    
    [q writeObject:@(2)];
    INTEXPECT( q.count, 0 ,@"should have flushed immediately");
    IDEXPECT(a, (@[@(1),@(2)]),@"target");
}


+testSelectors
{
    return @[
             @"testDrainForwardsAllToTarget",
             @"testTriggeringWorksSameAsDrain",
             @"testAutoflushDrainsImmediately",
             @"testDupsAreRejectedWhenUniquing",
             ];
}

@end
