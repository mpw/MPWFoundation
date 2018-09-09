//
//  MPWWriteBackCache.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/9/18.
//

#import "MPWWriteBackCache.h"
#import "MPWRESTCopyStream.h"
#import "MPWRESTOperation.h"

@implementation MPWWriteBackCache

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource cache:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newCache
{
    self=[super initWithSource:newSource cache:newCache];
    MPWRESTCopyStream *s=[[[MPWRESTCopyStream alloc] initWithSource:(MPWAbstractStore*)newCache target:(MPWAbstractStore*)newSource] autorelease];
    
    self.streamCopier=s;
    return self;
}

-(void)writeToSource:newObject forReference:(id <MPWReferencing>)aReference
{
    if (!self.readOnlySource) {
        [self.streamCopier writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
    }
}


-(void)dealloc
{
    [(NSObject*)_streamCopier release];
    [super dealloc];
}


@end
