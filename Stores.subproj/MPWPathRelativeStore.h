//
//  MPWPathRelativeStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import <MPWFoundation/MPWMappingStore.h>

@protocol MPWIdentifying;

@interface MPWPathRelativeStore : MPWMappingStore

+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWIdentifying>)newRef;
-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWIdentifying>)newRef;

@property (readonly) id <MPWIdentifying> baseReference;

@end
