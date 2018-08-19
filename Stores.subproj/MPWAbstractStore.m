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
