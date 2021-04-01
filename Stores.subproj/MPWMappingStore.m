//
//  MPWMappingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWMappingStore.h"
#import "MPWGenericReference.h"
#import <AccessorMacros.h>
#import <MPWByteStream.h>
#import "MPWDirectoryBinding.h"

@implementation MPWMappingStore


CONVENIENCEANDINIT(store, WithSource:newSource )
{
    self=[super init];
    self.source=newSource;
    return self;
}

-(id <MPWReferencing>)mapReference:(id <MPWReferencing>)aReference
{
    return aReference;
}

-mapRetrievedObject:anObject forReference:(id <MPWReferencing>)aReference
{
    return anObject;
}

-mapObjectToStore:anObject forReference:(id <MPWReferencing>)aReference
{
    return anObject;
}

-at:(id <MPWReferencing>)aReference
{
    return [self mapRetrievedObject:[self.source at:[self mapReference:aReference]] forReference:aReference];
}

-(void)at:(id <MPWReferencing>)aReference put:theObject
{
    [self.source at:[self mapReference:aReference] put:[self mapObjectToStore:theObject forReference:aReference]];
}

-(void)merge:theObject at:(id <MPWReferencing>)aReference
{
    [self.source merge:[self mapObjectToStore:theObject forReference:aReference] at:[self mapReference:aReference]];
}

-(void)deleteAt:(id <MPWReferencing>)aReference
{
    [self.source deleteAt:[self mapReference:aReference]];
}

-(BOOL)hasChildren:(id<MPWReferencing>)aReference
{
    return [self.source hasChildren:[self mapReference:aReference]];
}

-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWReferencing>)aReference
{
    return [[self mapRetrievedObject:[[[MPWDirectoryBinding alloc] initWithContents:[self.source childrenOfReference:[self mapReference:aReference]]] autorelease] forReference:aReference] contents];
}

-(MPWReference*)referenceForPath:(NSString*)path
{
//    NSLog(@"referenceForPath: %@ source store: %@",path,self.source);
    id result = self.source ? [self.source referenceForPath:path] : [super referenceForPath:path];
//    NSLog(@"resulting reference: %@",result);
    return result;

}



-(void)setSourceStores:(NSArray<MPWStorage> *)stores
{
    NSAssert1(stores.count <= 1, @"number of source stores should be <= 1, is %d", (int)stores.count);
    self.source=stores.firstObject;
}


-(void)graphViz:(MPWByteStream*)aStream
{
    [super graphViz:aStream];
    [aStream printFormat:@" -> %@ [label=\" source \"]\n",[self.source graphVizName]];
    [self.source graphViz:aStream];
}


-(NSArray*)schemeNames
{
    return @[ @"source" ];
}

-(void)dealloc
{
    [_source release];
    [super dealloc];
}

@end


#import "DebugMacros.h"
#import "MPWDictStore.h"

@implementation MPWMappingStore(testing)


+(void)testMapperPassesThrough
{
    MPWDictStore *store=[MPWDictStore store];
    store[@"hi"]=@"there";
    MPWMappingStore *mapper=[self storeWithSource:store];
    IDEXPECT( mapper[@"hi"], @"there", @"read via mapper");
    mapper[@"hello"]=@"world";
    IDEXPECT( store[@"hello"], @"world", @"write via mapper");
    [mapper deleteAt:@"hello"];
    EXPECTNIL( store[@"hello"], @"original after delete via mapper");
}

+testSelectors
{
    return @[
             @"testMapperPassesThrough"
             ];
    
}

@end

