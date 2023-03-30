//
//  MPWCachingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/1/18.
//

#import "MPWCachingStore.h"
#import "MPWDictStore.h"
#import <AccessorMacros.h>
#import "MPWGenericReference.h"
#import "DebugMacros.h"
#import "MPWMergingStore.h"
#import <MPWByteStream.h>

@interface MPWWriteThroughCache()

@property (nonatomic, strong) id <MPWHierarchicalStorage> cache;

@end

@implementation MPWWriteThroughCache

CONVENIENCEANDINIT(store, WithSource:newSource cache:newCache )
{
    self=[super initWithSource:newSource];
    self.cache=newCache;
    return self;
}

CONVENIENCEANDINIT(store, WithSource:newSource )
{
    return [self initWithSource:newSource cache:[MPWDictStore store]];
}

+(instancetype)memoryStore
{
    return [[[self alloc] initWithSource:nil cache:[MPWDictStore store]] autorelease];
}

-(instancetype)init
{
    return [self initWithSource:nil cache:[MPWDictStore store]];
}

-(id)doCopyFromSourceToCache:(id <MPWReferencing>)aReference
{
    id result=[self.source at:aReference];
    [self.cache at:aReference put:result];
    return result;
}

-at:(id <MPWReferencing>)aReference
{
    id result=[self.cache at:aReference];
    if (!result ) {
        result = [self doCopyFromSourceToCache:aReference];
    }
    return result;
}

-(void)writeToSource:newObject at:(id <MPWReferencing>)aReference
{
    if (!self.readOnlySource) {
        [self.source at:aReference put:newObject];
    }
}

-(void)at:(id <MPWReferencing>)aReference put:newObject
{
    [self.cache at:aReference put:newObject];
    [self writeToSource:newObject at:aReference];
}


-(void)merge:newObject at:(id <MPWReferencing>)aReference
{
    [self doCopyFromSourceToCache:aReference];
    [self.cache merge:newObject at:aReference];
    [self writeToSource:[self.cache at:aReference] at:aReference];
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    [self.cache deleteAt:aReference];
    [self.source deleteAt:aReference];
}

-(void)invalidate:(id)aRef
{
    [self.cache deleteAt:aRef];
}

-(void)setSourceStores:(NSArray<MPWStorage> *)stores
{
    if ( !self.cache ) {
        NSAssert1(stores.count == 2, @"number of source stores should be == 2, is %d", (int)stores.count);
    }
    self.cache=stores.firstObject;
    self.source=stores.lastObject;
}

-(void)setStoreDict:(NSDictionary*)storeDict
{
    self.cache=storeDict[@"cache"];
    self.source=storeDict[@"source"];
}

-(NSArray<MPWReferencing>*)childrenOfReference:(id <MPWReferencing>)aReference
{
    NSArray<MPWReferencing>* sourceRefs = [super childrenOfReference:aReference];
//    NSArray<MPWReferencing>* cacheRefs = [(id <MPWHierarchicalStorage>)self.cache childrenOfReference:aReference];
//    NSMutableSet<MPWReferencing> *allRefs=(NSMutableSet<MPWReferencing> *)[NSMutableSet setWithArray:sourceRefs];
//    [allRefs addObjectsFromArray:cacheRefs];
//    NSLog(@"allRefs: %@",allRefs);
//    NSArray<MPWReferencing>* sortedRefs= (NSArray<MPWReferencing>*)([allRefs.allObjects sortedArrayUsingSelector:@selector(compare:)]);
//    NSLog(@"sortedRefs: %@",sortedRefs);
//    return sortedRefs;
    return sourceRefs;
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"%@ -> %@ [label=cache]\n",[self graphVizName],[self.cache graphVizName]];
    [self.cache graphViz:aStream];
    [aStream printFormat:@"%@ -> %@ [label=source]\n",[self graphVizName],[self.source graphVizName]];
    [self.source graphViz:aStream];
    [aStream printFormat:@"\n"];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p source: %@ cache: %@>",self.class,self,self.source,self.cache];
}

-(void)dealloc
{
    [_cache release];
    [super dealloc];
}


@end



@implementation MPWWriteThroughCache(testing)



+testFixture
{
    return [[[MPWCachingStoreTests alloc] initWithTestClass:self] autorelease];
}


+testSelectors
{
    return @[
             @"testReadingPopulatesCache",
             @"testCacheIsReadFirst",
             @"testWritePopulatesCacheAndSource",
             @"testWritePopulatesCacheAndSourceUnlessDontWriteIsSet",
             @"testCanInvalidateCache",
             @"testMergeWorksLikeStore",
             @"testMergingFetchesFirst",
             @"testCanDelete",
             ];
}

@end


@implementation MPWCachingStoreTests

-(instancetype)initWithTestClass:(Class)testClass
{
    self=[super init];
    self.key = [MPWGenericReference referenceWithPath:@"aKey"];
    self.value = @"Hello World";
    self.cache = [MPWDictStore store];
    self.source = [MPWDictStore store];
    self.store = [testClass storeWithSource:self.source cache:self.cache];
    return self;
}

-(void)testReadingPopulatesCache
{
    id resultFromCache = self.cache[self.key];
    EXPECTNIL( resultFromCache , @"shouldn't have anything yet");
    [self.source at:self.key put:self.value];
    id mainResult = self.store[self.key];
    IDEXPECT( mainResult, self.value, @"reading the cache");
    resultFromCache = self.cache[self.key];
    IDEXPECT( resultFromCache, self.value, @"after accessing caching store, cache is populated");
}

-(void)testCacheIsReadFirst
{
    id resultFromCache = self.cache[self.key];
    EXPECTNIL( resultFromCache , @"shouldn't have anything yet");
    [self.cache at:self.key put:self.value];
    id resultFromSource = self.source[self.key];
    EXPECTNIL( resultFromSource , @"nothing in source");
    id mainResult = self.store[self.key];
    IDEXPECT( mainResult, self.value, @"reading the cache");
}

-(void)testWritePopulatesCacheAndSource
{
    [self.store at:self.key put:self.value];
    IDEXPECT( [self.source at:self.key], self.value, @"reading the source");
    IDEXPECT( [self.cache at:self.key], self.value, @"reading the cache");
}

-(void)testWritePopulatesCacheAndSourceUnlessDontWriteIsSet
{
    self.store.readOnlySource=YES;
    [self.store at:self.key put:self.value];
    EXPECTNIL( [self.source at:self.key], @"reading the source");
    IDEXPECT( [self.cache at:self.key], self.value, @"reading the cache");
}

-(void)testCanInvalidateCache
{
    [self.store at:self.key put:self.value];
    [self.store invalidate:self.key];
    EXPECTNIL( self.cache[self.key] , @"cache should be gone");
    IDEXPECT( self.source[self.key] ,self.value, @"source should still be there");
}

-(void)testCanDelete
{
    [self.store at:self.key put:self.value];
    [self.store deleteAt:self.key];
    EXPECTNIL( self.cache[self.key] , @"cache should be gone");
    EXPECTNIL( self.source[self.key] , @"source should be gone");
}

-(void)testMergeWorksLikeStore
{
    [self.store merge:self.value at:self.key];
    IDEXPECT( [self.source at:self.key], self.value, @"reading the source");
    IDEXPECT( [self.cache at:self.key], self.value, @"reading the cache");
}

-(void)testMergingFetchesFirst
{
    self.cache = (id)[MPWMergingStore storeWithSource:self.cache];
    self.store = [[self.store class] storeWithSource:self.source cache:self.cache];
    self.source[self.key]=@"hi";
    [self.store merge:@" there" at:self.key];
    IDEXPECT( self.store[self.key], @"hi there",@"merging with unitialized cache");
}


-(void)dealloc
{
    [_key release];
    [_value release];
    [_cache release];
    [_source release];
    [_store release];
    [super dealloc];
}

@end


@implementation MPWCachingStore
@end

