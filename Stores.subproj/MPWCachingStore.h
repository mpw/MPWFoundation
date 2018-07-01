//
//  MPWCachingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/1/18.
//

#import <MPWFoundation/MPWMappingStore.h>

@interface MPWCachingStore : MPWMappingStore

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource cache:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newCache;

-(void)invalidate:(id <MPWReferencing>)aRef;

@end
