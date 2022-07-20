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
-(void)flush;

@property (readonly) BOOL isAsynchronous;
@property (readonly) BOOL hasChanges;
@property (assign)   BOOL autoFlush;

@end
