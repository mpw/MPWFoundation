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
#import "NSObjectFiltering.h"
#import "NSDictAdditions.h"
#import "MPWPathRelativeStore.h"
#import "MPWRESTCopyStream.h"
#import "MPWLoggingStore.h"

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
        storeDescription=[self storesWithDescription:storeDescription].firstObject;
    }
    return storeDescription;
}

+(NSArray*)storesWithDescription:(NSArray*)storeDescriptions
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
    return [self storesWithDescription:storeDescriptions].firstObject;
}

-(instancetype)initWithArray:(NSArray *)stores
{
    return [[[self class] stores:stores] retain];
}

-at:(MPWReference*)aReference
{
    return nil;
}

-(void)at:(MPWReference*)aReference put:theObject
{
    return ;
}

-(id)at:(MPWReference*)aReference post:theObject
{
    return nil;
}

-(void)merge:theObject at:(id <MPWReferencing>)aReference
{
    [self at:aReference put:theObject];
}

-(void)deleteAt:(MPWReference*)aReference
{
    return ;
}

-(BOOL)hasChildren:(id <MPWReferencing>)aReference
{
    return NO;
}

-objectForKeyedSubscript:key
{
    return [self at:[key asReference]];
}

-(void)setObject:(id)theObject forKeyedSubscript:(nonnull id<NSCopying>)key
{
    [self at:(NSString*)key put:theObject];
}




-(NSArray<MPWReferencing>*)childrenOfReference:(id <MPWReferencing>)aReference
{
//    NSLog(@"-childrenOfReference: %@ %@/'%@'",[self class],[(NSObject*)aReference class],aReference);
    id maybeChildren = [self at:aReference];
//    NSLog(@"children: %@",[maybeChildren class]);
    if ( [maybeChildren respondsToSelector:@selector(objectAtIndex:)]) {
        return maybeChildren;
    } else if ( [maybeChildren respondsToSelector:@selector(contents)]) {
        return (NSArray<MPWReferencing>*)[maybeChildren contents];
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

-(MPWDirectoryBinding*)listForNames:(NSArray*)nameList
{
    return [[[MPWDirectoryBinding alloc] initWithContents:[[MPWGenericReference collect] referenceWithPath:[nameList each]]] autorelease];
}


-(MPWRESTCopyStream*)syncToTarget:(id <MPWStorage>)target
{
    MPWRESTCopyStream *copier = [[MPWRESTCopyStream alloc] initWithSource:self target:target];
    MPWLoggingStore *logger = [self logger];
    [logger setLog:copier];
    return copier;
}

-(void)copyFrom:(id <MPWStorage>)source
{
    MPWRESTCopyStream *copier = [[MPWRESTCopyStream alloc] initWithSource:source target:self];
    [copier update];
}

-(void)copyTo:(id <MPWStorage>)dest
{
    [dest copyFrom:self];
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

-(id <Streaming>)writeStreamAt:(id <MPWReferencing>)aReference
{
    return nil;
}

-(void)at:(id <MPWReferencing>)aReference readToStream:(id <Streaming>)aStream
{
    return ;
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

-(id<MPWStorage>)relativeStoreAt:(id <MPWReferencing>)reference
{
    return [MPWPathRelativeStore storeWithSource:self reference:reference];
}

-(void)mkdirAt:(id <MPWReferencing>)reference
{
    [self at:reference put:nil];
}



-(void)dealloc
{
    [_name release];
    [_errors release];
    [super dealloc];
}



@end

@implementation MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifier withContext:aContext
{
    id value = [self at:anIdentifier];
    
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
        retval = [[self at:[self referenceForPath:uriString]] retain];
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

-(void)put:anObject at:ref
{
    [self at:ref put:anObject];
}


-get:uri
{
    return [self get:uri parameters:nil];
}


@end

@implementation NSDictionary(storeLegacy)

-evaluateIdentifier:anIdentifier withContext:aContext
{
    id value = [self at:anIdentifier];
    
    if ( [value respondsToSelector:@selector(isNotNil)]  && ![value isNotNil] ) {
        value=nil;
    }
    return value;
}

-referenceForPath:aPath
{
    return aPath;
}

-(void)setEvaluator:anEvaluator {}
-(id)evaluator { return nil; }

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

