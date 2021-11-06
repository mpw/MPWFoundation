//
//  MPWCompositeStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.11.18.
//

#import "MPWCompositeStore.h"
#import <MPWByteStream.h>
#import "MPWDiskStore.h"
#import "MPWReference.h"

@implementation MPWCompositeStore

+(instancetype)stores:(NSArray *)storeDescriptions
{
    MPWCompositeStore *store=[super store];
    store.stores=[self storesWithDescription:storeDescriptions];
    return store;
}

-(id)at:(id<MPWReferencing>)aReference
{
    return [self.stores.firstObject at:aReference];
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    [self.stores.firstObject at:aReference put:(id)theObject];
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    [self.stores.firstObject deleteAt:aReference];
}

-(void)merge:(id)theObject at:(id<MPWReferencing>)aReference
{
    [self.stores.firstObject merge:(id)theObject at:aReference];
}

-(void)graphViz:(MPWByteStream *)aStream
{
    [aStream printFormat:@"%@\n",[self graphVizName]];
    [aStream writeObject:@" -> "];
    [self.stores.firstObject graphViz:aStream];
}

-(void)dealloc
{
    [_stores release];
    [super dealloc];
}


@end

#import "DebugMacros.h"
#import "MPWMappingStore.h"
#import "MPWCachingStore.h"
#import "MPWDictStore.h"
#import "MPWSequentialStore.h"
#import "MPWPathRelativeStore.h"

@implementation MPWCompositeStore(testing)

+(void)testConstructingDifferentStoreHierarchiesWithArrays
{
    MPWAbstractStore *s1=[self stores:@[ [MPWAbstractStore store]]];
    EXPECTTRUE([s1 isKindOfClass:[MPWAbstractStore class]], @"simple store");
    MPWAbstractStore *s2=[self stores:@[ [MPWAbstractStore class]]];
    EXPECTTRUE([s2 isKindOfClass:[MPWAbstractStore class]], @"classes get replaced by instances");
    MPWCachingStore *s3=[MPWCachingStore stores:@[ [MPWMappingStore class], [MPWAbstractStore class]]];
    EXPECTTRUE([s3 isKindOfClass:[MPWMappingStore class]], @"first element of sequence is a mapping store");
    EXPECTTRUE([[s3 source] isKindOfClass:[MPWAbstractStore class]], @"stores are connected");

    MPWCachingStore *s4=[MPWCachingStore stores:@[ [MPWCachingStore class], @[ @[ [MPWDictStore class]] , @[ [MPWAbstractStore class]]] ]];
    EXPECTTRUE([s4 isKindOfClass:[MPWCachingStore class]], @"first element of sequence is a caching store");
    EXPECTTRUE([[s4 cache] isKindOfClass:[MPWDictStore class]], @"cache of caching store is connected");
    EXPECTTRUE([[s4 source] isKindOfClass:[MPWAbstractStore class]], @"source of caching store is connected");

    MPWSequentialStore *s5=[MPWSequentialStore stores:@[ [MPWSequentialStore class], @[ @[ [MPWDictStore class]] , @[ [MPWAbstractStore class]], @[ [MPWMappingStore class] ] ]]];
    EXPECTTRUE([s5 isKindOfClass:[MPWSequentialStore class]], @"first element of sequence is a sequential store");
    INTEXPECT(s5.stores.count, 3, @"number of stores");
    EXPECTTRUE( [s5.stores.firstObject isKindOfClass:[MPWDictStore class]], @"first of caching store is connected");
    EXPECTTRUE( [s5.stores.lastObject isKindOfClass:[MPWMappingStore class]], @"cache of caching store is connected");

    MPWMappingStore *s6=[MPWMappingStore stores:@[ [MPWPathRelativeStore class], [MPWMappingStore class] , [MPWDictStore class] ]];
    EXPECTTRUE([s6 isKindOfClass:[MPWPathRelativeStore class]], @"first element of sequence is a sequential store");
    MPWMappingStore *s61 = (MPWMappingStore*)[s6 source];
    EXPECTTRUE([s61 isKindOfClass:[MPWMappingStore class]], @"first element of sequence is a sequential store");
    MPWDictStore *s62 = (MPWDictStore*)[s61 source];
    NSLog(@"s61: %@",s61);
    NSLog(@"s62: %@",s62);
    EXPECTTRUE([s62 isKindOfClass:[MPWDictStore class]], @"last element is a dict store");

}

+(void)testConstructingAStoreHierarchyWithDictionary
{
    MPWCachingStore *s1=[MPWCachingStore stores:@[ [MPWCachingStore class],
                                                   @{ @"cache":  [MPWDictStore class] ,
                                                      @"source": [MPWAbstractStore class] }]];
    EXPECTTRUE( [s1 isKindOfClass:[MPWCachingStore class]], @"should be a caching store");
    EXPECTNOTNIL( s1.cache ,@"has cache");

    MPWCachingStore *s2=[MPWCachingStore stores:@[ [MPWCachingStore class],
                                                   @{ @"cache": @[ [MPWMappingStore class], [MPWDictStore class] ],
                                                      @"source": [MPWAbstractStore class] }]];
    EXPECTTRUE( [s2 isKindOfClass:[MPWCachingStore class]], @"should be a caching store");
    EXPECTNOTNIL( s2.cache ,@"has cache");
    MPWMappingStore *cache=(MPWMappingStore*)s2.cache;
    EXPECTTRUE( [cache isKindOfClass:[MPWMappingStore class]], @"should be a mapping store");
    MPWDictStore *cacheSource=(MPWDictStore*)cache.source;
    EXPECTTRUE( [cacheSource isKindOfClass:[MPWDictStore class]], @"should be a dict store");

}

+(void)testCanPutStoresDirectlyInSquentialStoreConstructionDescription
{
    MPWSequentialStore *s1=[MPWSequentialStore stores:@[ [MPWSequentialStore class],@[ [MPWDictStore store], [MPWAbstractStore class]] ]];
    EXPECTTRUE( [s1 isKindOfClass:[MPWSequentialStore class]],@"constructed a sequential store");
    NSArray *substores=[s1 stores];
    INTEXPECT( [substores count],2,@"number of substores");
    EXPECTTRUE( [substores.firstObject isKindOfClass:[MPWDictStore class]],@"first is a dict store");
    EXPECTTRUE( [substores.lastObject isKindOfClass:[MPWAbstractStore class]],@"last is an abstract store");
}

+(void)testGraphVizOutput
{
    MPWMappingStore *s3=[MPWMappingStore stores:@[ [MPWMappingStore class], [MPWAbstractStore class]]];
    IDEXPECT( [s3 graphViz], @"\"MPWMappingStore\"\n -> \"MPWAbstractStore\" [label=\" source \"]\n\"MPWAbstractStore\"\n", @"");

    MPWCachingStore *s4=[MPWCachingStore stores:@[ [MPWCachingStore class], @[ @[ [MPWDictStore class]] , @[ [MPWAbstractStore class]]] ]];
    IDEXPECT( [s4 graphViz], @"\"MPWCachingStore\" -> \"MPWDictStore\" [label=cache]\n\"MPWDictStore\"\n\"MPWCachingStore\" -> \"MPWAbstractStore\" [label=source]\n\"MPWAbstractStore\"\n\n", @"");

}

+(void)testGraphVizOutputForCompositeStore
{
    MPWCompositeStore *s3=[self stores:@[ [MPWMappingStore class], [MPWAbstractStore class]]];
    IDEXPECT( [s3 graphViz], @"\"MPWCompositeStore\"\n -> \"MPWMappingStore\"\n -> \"MPWAbstractStore\" [label=\" source \"]\n\"MPWAbstractStore\"\n", @"");

    MPWCompositeStore *s4=[self stores:@[ [MPWCachingStore class], @[ @[ [MPWDictStore class]] , @[ [MPWAbstractStore class]]] ]];
    INTEXPECT( s4.stores.count , 1, @"only 1 top level store");
    NSString *gv=[s4 graphViz];
    IDEXPECT( gv, @"\"MPWCompositeStore\"\n -> \"MPWCachingStore\" -> \"MPWDictStore\" [label=cache]\n\"MPWDictStore\"\n\"MPWCachingStore\" -> \"MPWAbstractStore\" [label=source]\n\"MPWAbstractStore\"\n\n", @"");

}

+(void)testCompositePassesThrough
{
    MPWCompositeStore *store=[self stores:@[ [MPWDictStore class] ]];
    store[@"hi"]=@"there";
    IDEXPECT( store[@"hi"], @"there", @"set and get")
    [store deleteAt:@"hi"];
    EXPECTNIL( store[@"hi"], @"delete works");
    [store merge:@"world" at:@"hi"];
    IDEXPECT( store[@"hi"], @"world", @"merge works like set")
}

+(void)testCompositeConstruction
{
    MPWCompositeStore *s4=[self stores:@[ [MPWCachingStore class], @[ @[ [MPWDictStore class]] , @[ [MPWDiskStore class]]] ]];
    INTEXPECT( s4.stores.count , 1, @"only 1 top level store");
    MPWCachingStore *cs = s4.stores.firstObject;
    EXPECTTRUE( [cs.cache isKindOfClass:[MPWDictStore class]],@"should have a dict store as cache");
    EXPECTTRUE( [cs.source isKindOfClass:[MPWDiskStore class]],@"should have aa disk store as source");
}

+(NSArray*)testSelectors
{
    return @[
             @"testConstructingDifferentStoreHierarchiesWithArrays",
             @"testConstructingAStoreHierarchyWithDictionary",
             @"testCanPutStoresDirectlyInSquentialStoreConstructionDescription",
             @"testGraphVizOutput",
             @"testGraphVizOutputForCompositeStore",
             @"testCompositeConstruction",
             @"testCompositePassesThrough",
             ];
}

@end
