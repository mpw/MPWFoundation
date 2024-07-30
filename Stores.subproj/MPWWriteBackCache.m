//
//  MPWWriteBackCache.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/9/18.
//

#import "MPWWriteBackCache.h"
#import "MPWRESTCopyStream.h"
#import "MPWRESTOperation.h"
#import "MPWQueue.h"
#import "MPWDictStore.h"
#import "NSThreadWaiting.h"


@interface MPWWriteBackCache()

@property (nonatomic, retain)  id <Streaming> streamCopier;
@property (nonatomic, retain)  MPWQueue *queue;


@end


@implementation MPWWriteBackCache

-(BOOL)autoFlush
{
    return self.queue.autoFlush;
}

-(void)setAutoFlush:(BOOL)flushing
{
    self.queue.autoFlush=flushing;
}

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource cache:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newCache
{
    self=[super initWithSource:newSource cache:newCache];
    MPWRESTCopyStream *s=[[[MPWRESTCopyStream alloc] initWithSource:(MPWAbstractStore*)newCache target:(MPWAbstractStore*)newSource] autorelease];
    MPWQueue *q=[MPWQueue queueWithTarget:s uniquing:YES];
    q.autoFlush=YES;
    self.streamCopier=s;
    self.queue=q;
    return self;
}

-(void)writeToSource:newObject at:(id <MPWIdentifying>)aReference
{
    if (!self.readOnlySource) {
        [self.queue writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
    }
}

-(void)deleteAt:(id<MPWIdentifying>)aReference
{
    [self.cache deleteAt:aReference];
    if (!self.readOnlySource) {
        [self.queue writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbDELETE]];
    }
}

-(void)makeAsynchronous
{
    [self.queue makeAsynchronous];
}

-(void)flush
{
    [self.queue drain];
}

-(BOOL)hasChanges
{
    return self.queue.count > 0;
}

-(BOOL)isAsynchronous
{
    return self.queue.isAsynchronous;
}

-(void)dealloc
{
    [(NSObject*)_streamCopier release];
    [_queue release];
    [super dealloc];
}

+testSelectors
{
    return @[
             @"testReadingPopulatesCache",
             @"testCacheIsReadFirst",
             @"testWritePopulatesCacheAndSource",
             @"testWritePopulatesCacheAndSourceUnlessDontWriteIsSet",
             @"testCanInvalidateCache",
             @"testMergeWorksLikeStore",
             @"testMergingFetchesFirst",
             @"testCanDelete",

             //

             @"testAsyncWrite",
             @"testAsyncDelete",
             @"testSyncWrite",
             ];
}


@end

#import "DebugMacros.h"

@implementation MPWCachingStoreTests(writeBackTests)

-(void)testAsyncWrite
{
    EXPECTTRUE( [self.store isKindOfClass:[MPWWriteBackCache class]], @"expected class");
    [(MPWWriteBackCache*)self.store makeAsynchronous];
    self.store[self.key] = self.value;
    IDEXPECT( self.cache[self.key], self.value, @"writing cache is synchronous");
    EXPECTNIL( self.source[self.key], @"writing source is not synchronous");
    [NSThread sleepForTimeInterval:2 orUntilConditionIsMet:^NSNumber *{
        return @(self.source[self.key] != nil);
    }];
    IDEXPECT( self.source[self.key], self.value, @"did write async");
}

-(void)testAsyncDelete
{
    self.store[self.key] = self.value;
    [(MPWWriteBackCache*)self.store makeAsynchronous];
    [self.store deleteAt:(id <MPWIdentifying>)self.key];
    IDEXPECT( self.source[self.key], self.value, @"deleteing source is not synchronous");
    EXPECTNIL( self.cache[self.key], @"deleteing cache is synchronous");
    [NSThread sleepForTimeInterval:2 orUntilConditionIsMet:^NSNumber *{
        return @(self.source[self.key] == nil);
    }];
    EXPECTNIL( self.source[self.key], @"deleteing source happens eventually");
}

-(void)testSyncWrite
{
    MPWWriteBackCache *store=(MPWWriteBackCache*)self.store;
    store.queue.autoFlush=NO;
    EXPECTTRUE( [store isKindOfClass:[MPWWriteBackCache class]], @"expected class");
    EXPECTFALSE(store.hasChanges,@"has changes");
    self.store[self.key] = self.value;
    IDEXPECT( self.cache[self.key], self.value, @"writing cache is synchronous");
    EXPECTTRUE(store.hasChanges,@"has changes");
    [store flush];
    IDEXPECT( self.source[self.key], self.value, @"did write async");
}


@end
