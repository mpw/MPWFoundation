//
//  MPWCachingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/1/18.
//

#import "MPWCachingStore.h"
#import "MPWDictStore.h"
#import "AccessorMacros.h"
#import "MPWGenericReference.h"
#import "DebugMacros.h"
#import "MPWMergingStore.h"
#import "MPWByteStream.h"

@interface MPWWriteThroughCache()

@property (nonatomic, strong) id <MPWStorage> cache;

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

-(instancetype)init
{
    return [self initWithSource:nil cache:[MPWDictStore store]];
}

-(id)doCopyFromSourceToCache:(id <MPWReferencing>)aReference
{
    id result=[self.source objectForReference:aReference];
    [self.cache setObject:result forReference:aReference];
    return result;
}

-objectForReference:(id <MPWReferencing>)aReference
{
    id result=[self.cache objectForReference:aReference];
    if (!result ) {
        result = [self doCopyFromSourceToCache:aReference];
    }
    return result;
}

-(void)writeToSource:newObject forReference:(id <MPWReferencing>)aReference
{
    if (!self.readOnlySource) {
        [self.source setObject:newObject forReference:aReference];
    }
}

-(void)setObject:newObject forReference:(id <MPWReferencing>)aReference
{
    [self.cache setObject:newObject forReference:aReference];
    [self writeToSource:newObject forReference:aReference];
}


-(void)mergeObject:newObject forReference:(id <MPWReferencing>)aReference
{
    [self doCopyFromSourceToCache:aReference];
    [self.cache mergeObject:newObject forReference:aReference];
    [self writeToSource:[self.cache objectForReference:aReference] forReference:aReference];
}

-(void)deleteObjectForReference:(id<MPWReferencing>)aReference
{
    [self.cache deleteObjectForReference:aReference];
    [self.source deleteObjectForReference:aReference];
}

-(void)invalidate:(id)aRef
{
    [self.cache deleteObjectForReference:aRef];
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


-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"%@ -> %@ [label=cache]\n",[self graphVizName],[self.cache graphVizName]];
    [self.cache graphViz:aStream];
    [aStream printFormat:@"%@ -> %@ [label=source]\n",[self graphVizName],[self.source graphVizName]];
    [self.source graphViz:aStream];
    [aStream printFormat:@"\n"];
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
    [self.source setObject:self.value forReference:self.key];
    id mainResult = self.store[self.key];
    IDEXPECT( mainResult, self.value, @"reading the cache");
    resultFromCache = self.cache[self.key];
    IDEXPECT( resultFromCache, self.value, @"after accessing caching store, cache is populated");
}

-(void)testCacheIsReadFirst
{
    id resultFromCache = self.cache[self.key];
    EXPECTNIL( resultFromCache , @"shouldn't have anything yet");
    [self.cache setObject:self.value forReference:self.key];
    id resultFromSource = self.source[self.key];
    EXPECTNIL( resultFromSource , @"nothing in source");
    id mainResult = self.store[self.key];
    IDEXPECT( mainResult, self.value, @"reading the cache");
}

-(void)testWritePopulatesCacheAndSource
{
    [self.store setObject:self.value forReference:self.key];
    IDEXPECT( [self.source objectForReference:self.key], self.value, @"reading the source");
    IDEXPECT( [self.cache objectForReference:self.key], self.value, @"reading the cache");
}

-(void)testWritePopulatesCacheAndSourceUnlessDontWriteIsSet
{
    self.store.readOnlySource=YES;
    [self.store setObject:self.value forReference:self.key];
    EXPECTNIL( [self.source objectForReference:self.key], @"reading the source");
    IDEXPECT( [self.cache objectForReference:self.key], self.value, @"reading the cache");
}

-(void)testCanInvalidateCache
{
    [self.store setObject:self.value forReference:self.key];
    [self.store invalidate:self.key];
    EXPECTNIL( self.cache[self.key] , @"cache should be gone");
    IDEXPECT( self.source[self.key] ,self.value, @"source should still be there");
}

-(void)testCanDelete
{
    [self.store setObject:self.value forReference:self.key];
    [self.store deleteObjectForReference:self.key];
    EXPECTNIL( self.cache[self.key] , @"cache should be gone");
    EXPECTNIL( self.source[self.key] , @"source should be gone");
}

-(void)testMergeWorksLikeStore
{
    [self.store mergeObject:self.value forReference:self.key];
    IDEXPECT( [self.source objectForReference:self.key], self.value, @"reading the source");
    IDEXPECT( [self.cache objectForReference:self.key], self.value, @"reading the cache");
}

-(void)testMergingFetchesFirst
{
    self.cache = (id)[MPWMergingStore storeWithSource:self.cache];
    self.store = [[self.store class] storeWithSource:self.source cache:self.cache];
    self.source[self.key]=@"hi";
    [self.store mergeObject:@" there" forReference:self.key];
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

