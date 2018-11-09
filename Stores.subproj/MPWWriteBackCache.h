//
//  MPWWriteBackCache.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/9/18.
//

#import "MPWCachingStore.h"

@protocol Streaming;

@interface MPWWriteBackCache : MPWWriteThroughCache

-(void)makeAsynchronous;
@property (readonly) BOOL isAsynchronous;


@end
