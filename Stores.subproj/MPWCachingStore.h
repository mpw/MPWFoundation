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
+(instancetype)memoryStore;

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource;
+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage>*)newSource;

-(void)invalidate:(id <MPWIdentifying>)aRef;

@property (readonly) id <MPWStorage> cache;
@property (nonatomic) BOOL readOnlySource;

-(void)writeToSource:newObject at:(id <MPWIdentifying>)aReference;

-(void)setStoreDict:(NSDictionary*)storeDict;

@end

@interface MPWCachingStore : MPWWriteThroughCache
@end

@class MPWDictStore;

@interface MPWCachingStoreTests : NSObject

@property (nonatomic, strong)  MPWGenericIdentifier *key;
@property (nonatomic, strong)  NSString *value;
@property (nonatomic, strong)  MPWDictStore *cache,*source;
@property (nonatomic, strong)  MPWCachingStore *store;

-(instancetype)initWithTestClass:(Class)testClass;

@end
