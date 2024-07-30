//
//  MPWMappingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWMappingStore.h"
#import "MPWGenericIdentifier.h"
#import <AccessorMacros.h>
#import <MPWByteStream.h>
#import "MPWDirectoryReference.h"

@implementation MPWMappingStore


CONVENIENCEANDINIT(store, WithSource:newSource )
{
    self=[super init];
    self.source=newSource;
    return self;
}

-(instancetype)init
{
    return [self initWithSource:nil];
}

-(id <MPWIdentifying>)mapReference:(id <MPWIdentifying>)aReference
{
    return aReference;
}

-(NSURL*)URLForReference:(MPWGenericIdentifier*)aReference
{
    return [self.source URLForReference:[self mapReference:aReference]];
}


-mapRetrievedObject:anObject forReference:(id <MPWIdentifying>)aReference
{
    return anObject;
}

-mapObjectToStore:anObject forReference:(id <MPWIdentifying>)aReference
{
    return anObject;
}

-at:(id <MPWIdentifying>)aReference
{
    return [self mapRetrievedObject:[self.source at:[self mapReference:aReference]] forReference:aReference];
}

-(void)at:(id <MPWIdentifying>)aReference put:theObject
{
    [self.source at:[self mapReference:aReference] put:[self mapObjectToStore:theObject forReference:aReference]];
}

-at:(id <MPWIdentifying>)aReference post:(id)theObject
{
    return [self.source at:[self mapReference:aReference] post:[self mapObjectToStore:theObject forReference:aReference]];
}

-(void)merge:theObject at:(id <MPWIdentifying>)aReference
{
    [self.source merge:[self mapObjectToStore:theObject forReference:aReference] at:[self mapReference:aReference]];
}

-(void)deleteAt:(id <MPWIdentifying>)aReference
{
    [self.source deleteAt:[self mapReference:aReference]];
}

-(id <Streaming>)writeStreamAt:(id <MPWIdentifying>)aReference
{
    return [self.source writeStreamAt:[self mapReference:aReference]];
}

-(void)at:(id <MPWIdentifying>)aReference readToStream:(id <Streaming>)aStream
{
    [[self source] at:[self mapReference:aReference] readToStream:aStream];
    return ;
}


-(BOOL)hasChildren:(id<MPWIdentifying>)aReference
{
    return [self.source hasChildren:[self mapReference:aReference]];
}

//-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWIdentifying>)aReference
//{
//    return [[self mapRetrievedObject:[[[MPWDirectoryReference alloc] initWithContents:[self.source childrenOfReference:[self mapReference:aReference]]] autorelease] forReference:aReference] contents];
//}

-(MPWIdentifier*)referenceForPath:(NSString*)path
{
//    NSLog(@"referenceForPath: %@ source store: %@",path,self.source);
    id result = self.source ? [self.source referenceForPath:path] : [super referenceForPath:path];
//    NSLog(@"resulting reference: %@",result);
    return result;

}

-(id <MPWIdentifying>)reverseMapReference:(id <MPWIdentifying>)aReference
{
    return aReference;
}


-childrenOfReference:aReference
{
    id mappedReference = [self mapReference:aReference];
    NSArray *refs=[self.source childrenOfReference:mappedReference];
    NSMutableArray *result = [NSMutableArray array];
    for ( id<MPWIdentifying> ref in refs ) {
        [result addObject:[self reverseMapReference:ref]];
    }
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

