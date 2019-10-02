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
#import "MPWDirectoryBinding.h"


@interface NSArray(unique)

-(NSArray*)uniqueObjects;

@end


@implementation MPWAbstractStore

+(instancetype)store
{
    return [[[self alloc] init] autorelease];
}

+(instancetype)mapStore:(id)storeDescription
{
    if ( [storeDescription respondsToSelector:@selector(store)]) {
        storeDescription=[storeDescription store];
    } else if ( [storeDescription isKindOfClass:[NSArray class]]) {
        storeDescription=[self mapStores:storeDescription].firstObject;
    }
    return storeDescription;
}

+(NSArray*)mapStores:(NSArray*)storeDescriptions
{
 //   NSMutableOrderedSet *stores=[NSMutableOrderedSet orderedSetWithCapacity:storeDescriptions.count];
    NSMutableArray *stores=[NSMutableArray arrayWithCapacity:storeDescriptions.count];
    id previous=nil;
    for ( id storeDescription in storeDescriptions) {
        if ( previous ) {
            [stores addObject:previous];
        }
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
                id subDescription=[descriptionDict objectForKey:key];
                [storeDict setObject:[self mapStore:subDescription] forKey:key];
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
    }
    if ( previous ) {
        [stores addObject:previous];
    }

    return [stores uniqueObjects];
}

+(instancetype)stores:(NSArray*)storeDescriptions
{
    return [self mapStores:storeDescriptions].firstObject;
}

-(instancetype)initWithArray:(NSArray *)stores
{
    return [[self class] stores:stores];
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

-(BOOL)hasChildren:(id <MPWReferencing>)aReference
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

-(BOOL)isLeafReference:(id <MPWReferencing>)aReference              //  is this compatibility
{
    return ![self hasChildren:aReference];
}

-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWReferencing>)aReference
{
    id maybeChildren = [self objectForReference:aReference];
    if ( [maybeChildren respondsToSelector:@selector(objectAtIndex:)]) {
        return maybeChildren;
    } else if ( [maybeChildren respondsToSelector:@selector(contents)]) {
        return [maybeChildren contents];
    } else {
        return nil;
    }
}

-(MPWReference*)referenceForPath:(NSString*)path
{
    return [MPWGenericReference referenceWithPath:path];
}

-(NSURL*)URLForReference:(MPWGenericReference*)aReference
{
    return [aReference URL];
}


-(NSString*)generatedName
{
    return [NSString stringWithFormat:@"\"%@\"",[[NSStringFromClass(self.class) componentsSeparatedByString:@"."] lastObject]];
}

-(NSString*)graphVizName
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
    [aStream printFormat:@"%@\n",[self graphVizName]];
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

-(MPWBinding*)bindingForReference:aReference inContext:aContext
{
    return [MPWBinding bindingWithReference:aReference inStore:self];
}

-(MPWBinding*)bindingForReference:aReference
{
    return [self bindingForReference:aReference inContext:nil];
}

-(MPWBinding*)bindingForPath:(NSString*)path
{
    return [self bindingForReference:[self referenceForPath:path]];
}

-(void)dealloc
{
    [_name release];
    [_errors release];
    [super dealloc];
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
    id retval;
    @autoreleasepool {
//        NSLog(@"will %@ get: %@",self,uriString);
        retval = [[self objectForReference:[self referenceForPath:uriString]] retain];
//        NSLog(@"will pop pool for %@ get: %@",self,uriString);
    }
//    NSLog(@"did pop pool");
    return retval;
}

-post:(NSString*)uriString parameters:uriParameters
{
    fprintf(stderr,"POST %s %s\n",[uriString UTF8String],[[uriParameters description] UTF8String]);
    return nil;
}

-propfind:(NSString*)uriString data:(NSData*)data parameters:uriParameters
{
    fprintf(stderr,"PROPFIND %s data: %ld bytes %s\n",[uriString UTF8String],(long)[data length],[[uriParameters description] UTF8String]);
    return nil;
}

-options:(NSString*)uriString parameters:uriParameters
{
    fprintf(stderr,"OPTIONS %s %s\n",[uriString UTF8String],[[uriParameters description] UTF8String]);
    return nil;
}

-put:(NSString*)uriString data:(NSData*)data parameters:uriParameters
{
    fprintf(stderr,"PUT %s data: %ld bytes %s\n",[uriString UTF8String],(long)[data length],[[uriParameters description] UTF8String]);
    return nil;
}


-patch:(NSString*)uriString data:(NSData*)data parameters:uriParameters
{
    NSLog(@"not handled -[%@ patch: %@ data: %ld bytes parameters: %@]",self,uriString,(long)[data length],uriParameters);
    return nil;
}



-get:uri
{
    return [self get:uri parameters:nil];
}

-at:ref
{
    return [self objectForReference:ref];
}

-(void)at:ref put:object
{
    [self setObject:object forReference:ref];
}

-(void)at:ref merge:object
{
    [self mergeObject:object forReference:ref];
}

-(void)deleteAt:ref
{
    [self deleteObjectForReference:ref];
}



@end


#import "DebugMacros.h"

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


+(NSArray*)testSelectors {  return @[
                                     @"testConstructingReferences",
                                     @"testGettingURLs",
                                     ]; }

@end



@implementation NSArray(unique)

-(NSArray*)uniqueObjects
{
    NSMutableArray *unique=[NSMutableArray array];
    @autoreleasepool {
        NSMutableSet *seen=[NSMutableSet set];
        for ( id obj in self ) {
            if ( ![seen containsObject:obj]) {
                [unique addObject:obj];
                [seen addObject:obj];
            }
        }
    }
    return unique;
}

@end

