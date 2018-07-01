//
//  MPWCachingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/1/18.
//

#import "MPWCachingStore.h"
#import "MPWDictStore.h"
#import "AccessorMacros.h"

@interface MPWCachingStore()

@property (nonatomic, strong) id <MPWStorage> cache;

@end

@implementation MPWCachingStore

CONVENIENCEANDINIT(store, WithSource:newSource cache:newCache )
{
    self=[super initWithSource:newSource];
    self.cache=newCache;
    return self;
}

-objectForReference:(id <MPWReferencing>)aReference
{
    id result=[self.cache objectForReference:aReference];
    if (!result ) {
        result=[self.source objectForReference:aReference];
        [self.cache setObject:result forReference:aReference];
    }
    return result;
}

-setObject:newObject forReference:(id <MPWReferencing>)aReference
{
    [self.cache setObject:newObject forReference:aReference];
    [self.source setObject:newObject forReference:aReference];
}

-(void)invalidate:(id)aRef
{
    [self.cache deleteObjectForReference:aRef];
}

@end

#import "DebugMacros.h"

@implementation MPWCachingStore(testing)

+(instancetype)_testCache
{
    return [self storeWithSource:[MPWDictStore store] cache:[MPWDictStore store]];
}

+(void)testReadingPopulatesCache
{
    MPWCachingStore *cache=[self _testCache];
    NSString *key=@"aKey";
    NSString *value=@"hi";
    MPWDictStore* theCache = cache.cache;
    id resultFromCache = theCache[key];
    EXPECTNIL( resultFromCache , @"shouldn't have anything yet");
    [cache.source setObject:value forReference:key];
    id mainResult = cache[key];
    IDEXPECT( mainResult, value, @"reading the cache");
    resultFromCache = theCache[key];
    IDEXPECT( resultFromCache, value, @"after accessing caching store, cache is populated");
    
}

+(void)testCacheIsReadFirst
{
    MPWCachingStore *cache=[self _testCache];
    NSString *key=@"aKey";
    NSString *value=@"hi";
    MPWDictStore* theCache = cache.cache;
    id resultFromCache = theCache[key];
    EXPECTNIL( resultFromCache , @"shouldn't have anything yet");
    [cache.cache setObject:value forReference:key];
    id resultFromSource = ((MPWDictStore*)cache.source)[key];
    EXPECTNIL( resultFromSource , @"nothing in source");
    id mainResult = cache[key];
    IDEXPECT( mainResult, value, @"reading the cache");
}

+(void)testWritePopulatesCacheAndSource
{
    MPWCachingStore *cache=[self _testCache];
    NSString *key=@"aKey";
    NSString *value=@"hi";
    
    [cache setObject:value forReference:key];
    IDEXPECT( [cache.source objectForReference:key], value, @"reading the source");
    IDEXPECT( [cache.cache objectForReference:key], value, @"reading the cache");
}

+(void)testCanInvalidateCache
{
    MPWCachingStore *cache=[self _testCache];
    NSString *key=@"aKey";
    NSString *value=@"hi";
    
    [cache setObject:value forReference:key];
    IDEXPECT( [cache.source objectForReference:key], value, @"reading the source");
    IDEXPECT( [cache.cache objectForReference:key], value, @"reading the cache");
    [cache invalidate:key];
    MPWDictStore* theCache = cache.cache;
    id resultFromCache = theCache[key];
    EXPECTNIL( resultFromCache , @"cache should be invalidated");
}

+testSelectors
{
    return @[
         @"testMapperPassesThrough",   // superclass test
         @"testReadingPopulatesCache",
         @"testCacheIsReadFirst",
         @"testWritePopulatesCacheAndSource",
         @"testCanInvalidateCache",
         
      ];
}

@end
