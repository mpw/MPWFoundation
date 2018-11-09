//
//  MPWAbstractStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWAbstractStore.h"
#import "MPWGenericReference.h"
#import "NSNil.h"
#import "MPWByteStream.h"
#import "MPWWriteStream.h"

@implementation MPWAbstractStore

+(instancetype)store
{
    return [[[self alloc] init] autorelease];
}

-objectForReference:(MPWReference*)aReference
{
    return nil;
}

-(void)setObject:theObject forReference:(MPWReference*)aReference
{
    return ;
}

-(void)mergeObject:theObject forReference:(id <MPWReferencing>)aReference
{
    [self setObject:theObject forReference:aReference];
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    return ;
}

-(BOOL)hasChildren:(MPWReference*)aReference
{
    return NO;
}

-objectForKeyedSubscript:key
{
    return [self objectForReference:key];
}

-(void)setObject:(id)theObject forKeyedSubscript:(nonnull id<NSCopying>)key
{
    [self setObject:theObject forReference:(id <MPWReferencing>)key];
}

-(BOOL)isLeafReference:(MPWReference*)aReference
{
    return YES;
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    return @[];
}

-(MPWReference*)referenceForPath:(NSString*)path
{
    return [MPWGenericReference referenceWithPath:path];
}

-(NSURL*)URLForReference:(MPWGenericReference*)aReference
{
    return [aReference URL];
}

+(instancetype)mapStore:(id)storeDescription
{
    if ( [storeDescription respondsToSelector:@selector(store)]) {
        storeDescription=[storeDescription store];
    } else if ( [storeDescription isKindOfClass:[NSArray class]]) {
        storeDescription=[self stores:storeDescription];
    }
    return storeDescription;
}

+(instancetype)stores:(NSArray*)stores
{
    MPWAbstractStore *first=nil;
    MPWAbstractStore *previous=nil;
    for ( id storeDescription in stores) {
        if ( [storeDescription isKindOfClass:[NSArray class]] ) {
            NSMutableArray<MPWStorage> *substores=(id)[NSMutableArray array];
            for ( NSArray *subdescription in storeDescription) {
                MPWAbstractStore *substore=[self mapStore:subdescription];
                [substores addObject:substore];
            }
            [previous setSourceStores:substores];
        } else if ( [storeDescription isKindOfClass:[NSDictionary class]] ) {
            NSDictionary *descriptionDict=(NSDictionary*)storeDescription;
            NSMutableDictionary *storeDict=[NSMutableDictionary dictionary];
            for  (NSString *key in descriptionDict.allKeys ) {
                id subDescription=descriptionDict[key];
                storeDict[key]=[self mapStore:subDescription];
            }
            [previous setStoreDict:storeDict];
        } else {
            if ( [storeDescription respondsToSelector:@selector(store)]) {
                storeDescription=[storeDescription store];
            }
            if ( previous && [storeDescription respondsToSelector:@selector(setSourceStores:)]) {
                [previous setSourceStores:(NSArray<MPWStorage>*)@[ storeDescription ]];
            }
            previous=storeDescription;
            
        }
        if ( !first ) {
            first=storeDescription;
        }
    }
    return first;
}

-(NSString*)generatedName
{
    return [NSString stringWithFormat:@"\"%@\"",[[NSStringFromClass(self.class) componentsSeparatedByString:@"."] lastObject]];
}

-(NSString*)displayName
{
    return self.name ?: self.generatedName;
}

-(void)reportError:(NSError *)error
{
    if (error) {
        [self.errors writeObject:error];
    }
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"%@\n",[self displayName]];
}

-(NSString*)graphViz
{
    MPWByteStream *s=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [self graphViz:s];
    return (NSString*)s.target;
}

-(void)setSourceStores:(NSArray<MPWStorage> *)stores
{
   
}

-(void)setStoreDict:(NSDictionary*)storeDict
{
}


@end

@implementation MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifer withContext:aContext
{
    id value = [self objectForReference:anIdentifer];
    
    if ( [value respondsToSelector:@selector(isNotNil)]  && ![value isNotNil] ) {
        value=nil;
    }
    return value;
}

-get:(NSString*)uriString parameters:uriParameters
{
    return [self objectForReference:[self referenceForPath:uriString]];
}

-get:uri
{
    return [self get:uri parameters:nil];
}



@end


#import "DebugMacros.h"
#import "MPWMappingStore.h"
#import "MPWCachingStore.h"
#import "MPWDictStore.h"
#import "MPWSequentialStore.h"
#import "MPWPathRelativeStore.h"

@implementation MPWAbstractStore(testing)


+(void)testConstructingReferences
{
    MPWAbstractStore *store=[MPWAbstractStore store];
    id <MPWReferencing> r1=[store referenceForPath:@"somePath"];
    IDEXPECT(r1.path, @"somePath", @"can construct a reference");
}

+(void)testGettingURLs
{
    MPWAbstractStore *store=[MPWAbstractStore store];
    id <MPWReferencing> r1=[store referenceForPath:@"somePath"];
    IDEXPECT([[store URLForReference:r1] absoluteString] , @"somePath", @"can get a URL from a reference");
}

+(void)testConstructingDifferentStoreHierarchiesWithArrays
{
    MPWAbstractStore *s1=[MPWAbstractStore stores:@[ [MPWAbstractStore store]]];
    EXPECTTRUE([s1 isKindOfClass:[MPWAbstractStore class]], @"simple store");
    MPWAbstractStore *s2=[MPWAbstractStore stores:@[ [MPWAbstractStore class]]];
    EXPECTTRUE([s2 isKindOfClass:[MPWAbstractStore class]], @"classes get replaced by instances");
    MPWMappingStore *s3=[MPWMappingStore stores:@[ [MPWMappingStore class], [MPWAbstractStore class]]];
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
    IDEXPECT( [s3 graphViz], @"\"MPWMappingStore\"\n -> \"MPWAbstractStore\"\n", @"");

    MPWCachingStore *s4=[MPWCachingStore stores:@[ [MPWCachingStore class], @[ @[ [MPWDictStore class]] , @[ [MPWAbstractStore class]]] ]];
    IDEXPECT( [s4 graphViz], @"\"MPWCachingStore\" -> \"MPWDictStore\"\n\"MPWCachingStore\" -> \"MPWAbstractStore\"\n", @"");

}

+(NSArray*)testSelectors {  return @[
                                     @"testConstructingReferences",
                                     @"testGettingURLs",
                                     @"testConstructingDifferentStoreHierarchiesWithArrays",
                                     @"testConstructingAStoreHierarchyWithDictionary",
                                     @"testCanPutStoresDirectlyInSquentialStoreConstructionDescription",
                                     @"testGraphVizOutput",
                                     ]; }

@end
