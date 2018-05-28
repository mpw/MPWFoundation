//
//  MPWPathRelativeStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWGenericReference;

@interface MPWPathRelativeStore : MPWMappingStore

+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:(MPWGenericReference*)newRef;
-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:(MPWGenericReference*)newRef;

@end
