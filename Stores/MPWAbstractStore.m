//
//  MPWAbstractStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWAbstractStore.h"
#import "MPWGenericReference.h"
#import "NSNil.h"

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

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    return ;
}

-(NSArray*)childrenForReference:(MPWReference*)aReference
{
    return nil;
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
    [self setObject:theObject forReference:key];
}

-(BOOL)isLeafReference:(MPWReference*)aReference
{
    return YES;
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    return @[];
}

-(MPWGenericReference*)referenceForPath:(NSString*)path
{
    return [MPWGenericReference referenceWithPath:path];
}

-(MPWGenericReference*)referenceForPathComponents:(NSArray*)path schemeName:(NSString*)schemeName
{
    return [[[MPWGenericReference alloc] initWithPathComponents:path scheme:schemeName] autorelease];
}

-(NSURL*)URLForReference:(MPWGenericReference*)aReference
{
    return [aReference URL];
//    NSURLComponents *components=[[[NSURLComponents alloc] init] autorelease];
//    components.scheme = aReference.schemeName;
//    components.path = aReference.path;
//    return [components URL];
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

@implementation MPWAbstractStore(testing)

+(void)testGenericsWork
{
    MPWAbstractStore<NSString*,NSArray*> *store=[MPWAbstractStore new];
    [store setObject:@[] forReference:@""];
    NSArray *a=[store objectForReference:@""];
    EXPECTNOTNIL( store, @"should have a store");
    EXPECTNIL( a, @"should not have a result");
}

+(void)testConstructingReferences
{
    MPWAbstractStore<MPWGenericReference*,NSArray*> *store=[MPWAbstractStore new];
    MPWGenericReference *r1=[store referenceForPath:@"somePath"];
    IDEXPECT(r1.path, @"somePath", @"can construct a reference");
}

+(void)testGettingURLs
{
}

+(NSArray*)testSelectors {  return @[
                                     @"testGenericsWork",
                                     @"testConstructingReferences",
                                     @"testGettingURLs",
                                     ]; }

@end
