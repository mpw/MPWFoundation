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


@end
