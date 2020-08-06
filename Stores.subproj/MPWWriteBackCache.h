//
//  MPWWriteBackCache.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/9/18.
//

#import <MPWFoundation/MPWCachingStore.h>

@protocol Streaming;

@interface MPWWriteBackCache : MPWWriteThroughCache

-(void)makeAsynchronous;
@property (readonly) BOOL isAsynchronous;
@property (readonly) BOOL hasChanges;


@end
