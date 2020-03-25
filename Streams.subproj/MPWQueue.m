//
//  MPWUniquingQueue.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import "MPWQueue.h"
#import "AccessorMacros.h"
#import "NSThreadInterThreadMessaging.h"
#import "NSThreadWaiting.h"

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
@property (atomic, strong) NSThread* flusherThread;
@property (nonatomic, assign) id flusherRunLoop;
@property (nonatomic, assign) BOOL stopAsync;

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
        [[self onThread:self.flusherThread] drain];
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

-(void)_flusherThreadRunLoop
{
    if (!self.stopAsync) {
        @autoreleasepool {
            self.flusherRunLoop=(id)CFRunLoopGetCurrent();
            NSRunLoop *loop = [NSRunLoop currentRunLoop];
            [loop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
            CFRunLoopRun();
        }
    }
    self.flusherThread=nil;
}

-(void)_exitFlusherThread
{
    self.stopAsync=YES;
    if ( self.flusherRunLoop ) {
        CFRunLoopStop( (CFRunLoopRef)self.flusherRunLoop );
        self.flusherRunLoop=nil;
    }
}


-(void)setFlusherThreadName
{
    [self.flusherThread setName:[NSString stringWithFormat:@"Queue Processing Thread %@ %p", self.name, self]];
}

-(void)makeAsynchronous
{
    if ( !self.flusherThread) {
        self.flusherThread = [[[NSThread alloc] initWithTarget:self selector:@selector(_flusherThreadRunLoop) object:nil] autorelease];
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

-(BOOL)isAsynchronous
{
    return self.flusherThread != nil;
}

-(void)dealloc
{
    [self _exitFlusherThread];
    [_flusherThread release];
    [_queue release];
    [_inflight release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWQueue(testing)

+(instancetype)aTestQueue {
    return [self streamWithTarget:[NSMutableArray array]];
}


+(instancetype)filledTestQueue {
    let q=[MPWQueue aTestQueue];
    INTEXPECT(q.count, 0, @"0 objects added");
    [q writeObject:@(1)];
    [q writeObject:@(2)];
    [q writeObject:@(3)];
    INTEXPECT(q.count, 3, @"3 objects added");
    return q;
}

+(void)testDrainForwardsAllToTarget
{
    let q=[MPWQueue filledTestQueue];
    let a=(NSArray*)[q target];
    INTEXPECT(a.count, 0, @"0 objects forwarded");
    [q drain];
    INTEXPECT(a.count, 3, @"3 objects forwarded");
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testTriggeringWorksSameAsDrain
{
    let q=[MPWQueue filledTestQueue];
    let a=(NSArray*)[q target];
    [q triggerDrain];
    INTEXPECT(a.count, 3, @"3 objects forwarded");
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testDupsAreRejectedWhenUniquing
{
    let a=[NSMutableArray array];
    let q=[MPWQueue queueWithTarget:a uniquing:YES];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    INTEXPECT(q.count, 1, @"3 objects tried, only 1 added");

}

+(void)testAutoflushDrainsImmediately
{
    let q=[MPWQueue aTestQueue];
    [q setAutoFlush:YES];
    NSArray *a=(NSArray*)[q target];
    [q writeObject:@(1)];
    INTEXPECT( q.count, 0 ,@"should have flushed immediately");
    IDEXPECT(a, (@[@(1)]),@"target");
    
    [q writeObject:@(2)];
    INTEXPECT( q.count, 0 ,@"should have flushed immediately");
    IDEXPECT(a, (@[@(1),@(2)]),@"target");
}

+(void)testAsyncFlushing
{
    let q=[MPWQueue filledTestQueue];
    let a=(NSArray*)[q target];
    [q makeAsynchronous];
    [q triggerDrain];
    [NSThread sleepForTimeInterval:0.00001 orUntilConditionIsMet:^{
        return @( a.count == 3 );
    }];
    IDEXPECT(a, (@[ @(1), @(2), @(3)]), @"3 objects forwarded");
}

+(void)testAsyncAutoFlushing
{
    let q=[MPWQueue aTestQueue];
    let a=(NSArray*)[q target];
    EXPECTFALSE(q.isAsynchronous,@"is async");
    [q makeAsynchronous];
    EXPECTTRUE(q.isAsynchronous,@"is async");
    q.autoFlush=YES;
    INTEXPECT(a.count,0,@"before");
    [q writeObject:@"first"];
    INTEXPECT(a.count,0,@"directly after write, async drain shouldn't really have executed yet");
    [NSThread sleepForTimeInterval:0.00001 orUntilConditionIsMet:^{
        return @( a.count == 1 );
    }];
    IDEXPECT(a, (@[ @"first" ]), @"1 object auto-forwarded");
}

+(void)testStopAsync
{
    MPWQueue *q=[self aTestQueue];
    EXPECTFALSE(q.isAsynchronous,@"is async");
    [q makeAsynchronous];
    EXPECTTRUE(q.isAsynchronous,@"is async");
    [NSThread sleepForTimeInterval:0.01];
    [q _exitFlusherThread];
    [NSThread sleepForTimeInterval:0.1 orUntilConditionIsMet:^{
        return @( q.isAsynchronous == false );
    }];
    EXPECTFALSE(q.isAsynchronous,@"is async");

}

+(void)testStopAsyncBeforeItStarted
{
    MPWQueue *q=[self aTestQueue];
    EXPECTFALSE(q.isAsynchronous,@"is async");
    [q makeAsynchronous];
    EXPECTTRUE(q.isAsynchronous,@"is async");
    //    [NSThread sleepForTimeInterval:0.01];
    //    NSLog(@"will exit");
    [q _exitFlusherThread];
    [NSThread sleepForTimeInterval:0.1 orUntilConditionIsMet:^{
        return @( q.isAsynchronous == false );
    }];
    EXPECTFALSE(q.isAsynchronous,@"is async");

}


+testSelectors
{
    return @[
             @"testDrainForwardsAllToTarget",
             @"testTriggeringWorksSameAsDrain",
             @"testAutoflushDrainsImmediately",
             @"testDupsAreRejectedWhenUniquing",
             @"testAsyncFlushing",
             @"testAsyncAutoFlushing",
             @"testStopAsync",
             @"testStopAsyncBeforeItStarted",
//             @"testPersistQueue",
             ];
}

@end
