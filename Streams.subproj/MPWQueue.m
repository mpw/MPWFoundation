//
//  MPWUniquingQueue.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import "MPWQueue.h"

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

@end

@implementation MPWQueue

-(instancetype)initWithTarget:(id)aTarget uniquing:(BOOL)shouldUnique
{
    self=[super initWithTarget:aTarget];
    self.queue = shouldUnique ? [NSMutableOrderedSet orderedSet] : [NSMutableArray array];
    return self;
}

-(instancetype)initWithTarget:(id)aTarget
{
    return [self initWithTarget:aTarget uniquing:NO];
}

-(void)writeObject:(id)anObject
{
    @synchronized(self) {
        [self.queue addObject:anObject];
    }
}

-(void)removeFirstObject
{
    @synchronized(self) {
        [self.queue removeObjectAtIndex:0];
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
        [self removeFirstObject];
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

@implementation MPWQueue(testing)

+(void)testForwardingWorks
{
    NSMutableArray *a=[NSMutableArray array];
    MPWQueue *q=[self streamWithTarget:a];
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

+(void)testDupsAreRejectedWhenUniquing
{
    NSMutableArray *a=[NSMutableArray array];
    MPWQueue *q=[[[self alloc] initWithTarget:a uniquing:YES] autorelease];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    [q writeObject:@(1)];
    INTEXPECT(q.count, 1, @"3 objects tried, only 1 added");

}


+testSelectors
{
    return @[
             @"testForwardingWorks",
             @"testDupsAreRejectedWhenUniquing",
             ];
}

@end
