//
//  MPWPathRelativeStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import <MPWFoundation/MPWMappingStore.h>

@protocol MPWReferencing;

@interface MPWPathRelativeStore : MPWMappingStore

+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWReferencing>)newRef;
-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWReferencing>)newRef;

@property (readonly) id <MPWReferencing> baseReference;

@end
