//
//  MPWMappingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import <MPWFoundation/MPWAbstractStore.h>

@interface MPWMappingStore : MPWAbstractStore

@property (nonatomic, strong) NSObject<MPWStorage,MPWHierarchicalStorage,StreamStorage>* source;

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource;
+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource;

-(id <MPWIdentifying>)mapReference:(id <MPWIdentifying>)aReference;
-mapRetrievedObject:anObject forReference:(id <MPWIdentifying>)aReference;
-mapObjectToStore:anObject forReference:(id <MPWIdentifying>)aReference;

@end
