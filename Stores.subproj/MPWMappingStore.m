//
//  MPWMappingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWMappingStore.h"
#import "MPWGenericReference.h"
#import "AccessorMacros.h"

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

-mapRetrievedObject:anObject
{
    return anObject;
}

-mapObjectToStore:anObject
{
    return anObject;
}

-objectForReference:(id <MPWReferencing>)aReference
{
    return [self mapRetrievedObject:[self.source objectForReference:[self mapReference:aReference]]];
}

-(void)setObject:theObject forReference:(id <MPWReferencing>)aReference
{
    [self.source setObject:[self mapObjectToStore:theObject] forReference:[self mapReference:aReference]];
}

-(void)deleteObjectForReference:(id <MPWReferencing>)aReference
{
    [self.source deleteObjectForReference:[self mapReference:aReference]];
}

-(BOOL)isLeafReference:(id <MPWReferencing>)aReference
{
    return [self.source isLeafReference:[self mapReference:aReference]];
}

-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWReferencing>)aReference
{
    return [self.source childrenOfReference:[self mapReference:aReference]];
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
    [mapper deleteObjectForReference:@"hello"];
    EXPECTNIL( store[@"hello"], @"original after delete via mapper");
}

+testSelectors
{
    return @[
             @"testMapperPassesThrough"
             ];
    
}

@end

