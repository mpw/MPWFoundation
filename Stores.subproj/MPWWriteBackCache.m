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

-(void)writeToSource:newObject forReference:(id <MPWReferencing>)aReference
{
    if (!self.readOnlySource) {
        [self.queue writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
    }
}

-(void)deleteObjectForReference:(id<MPWReferencing>)aReference
{
    [self.cache deleteObjectForReference:aReference];
    if (!self.readOnlySource) {
        [self.queue writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbDELETE]];
    }
}



-(void)makeAsynchronous
{
    [self.queue makeAsynchronous];
}

-(BOOL)isAsynchronous
{
    return self.queue.isAsynchronous;
}

-(void)dealloc
{
    [(NSObject*)_streamCopier release];
    [self.queue release];
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
    [self.store deleteObjectForReference:(id <MPWReferencing>)self.key];
    EXPECTNIL( self.cache[self.key], @"deleteing cache is synchronous");
    IDEXPECT( self.source[self.key], self.value, @"deleteing source is not synchronous");
    [NSThread sleepForTimeInterval:2 orUntilConditionIsMet:^NSNumber *{
        return @(self.source[self.key] == nil);
    }];
    EXPECTNIL( self.source[self.key], @"deleteing source happens eventually");
}

@end
