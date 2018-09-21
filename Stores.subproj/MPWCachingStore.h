//
//  MPWCachingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/1/18.
//

#import <MPWFoundation/MPWMappingStore.h>

@interface MPWWriteThroughCache : MPWMappingStore

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource cache:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newCache;
+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource cache:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newCache;

-(void)invalidate:(id <MPWReferencing>)aRef;

@property (readonly) id <MPWStorage> cache;
@property (nonatomic) BOOL readOnlySource;

-(void)writeToSource:newObject forReference:(id <MPWReferencing>)aReference;

@end

@interface MPWCachingStore : MPWWriteThroughCache
@end
