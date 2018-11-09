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

             //

             @"testAsyncWrite",
             ];
}


@end

@implementation MPWCachingStoreTests(writeBackTests)

-(void)testAsyncWrite
{
    EXPECTTRUE( [self.store isKindOfClass:[MPWWriteBackCache class]], @"expected class");
    [(MPWWriteBackCache*)self.store makeAsynchronous];
    [self.store setObject:self.value forReference:self.key];
    IDEXPECT( [self.cache objectForReference:self.key], self.value, @"writing cache is synchronous");
    EXPECTNIL( [self.source objectForReference:self.key], @"writing source is not synchronous");
    [NSThread sleepForTimeInterval:2 orUntilConditionIsMet:^NSNumber *{
        return @([self.source objectForReference:self.key] != nil);
    }];
    IDEXPECT( [self.source objectForReference:self.key], self.value, @"did write async");

}

@end
