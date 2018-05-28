//
//  MPWMappingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWMappingStore.h"
#import "MPWReference.h"
#import "AccessorMacros.h"

@implementation MPWMappingStore


CONVENIENCEANDINIT(store, WithSource:newSource )
{
    self=[super init];
    self.source=newSource;
    return self;
}

-(MPWReference*)mapReference:(MPWReference*)aReference
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

-objectForReference:(MPWReference*)aReference
{
    return [self mapRetrievedObject:[self.source objectForReference:[self mapReference:aReference]]];
}

-(void)setObject:theObject forReference:(MPWReference*)aReference
{
    [self.source setObject:[self mapObjectToStore:theObject] forReference:[self mapReference:aReference]];
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    [self.source deleteObjectForReference:[self mapReference:aReference]];
}

-(BOOL)isLeafReference:(MPWReference*)aReference
{
    return [self.source isLeafReference:[self mapReference:aReference]];
}

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
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
    IDEXPECT( mapper[@"hi"], @"there", @"via mapper");
}

+testSelectors
{
    return @[
             @"testMapperPassesThrough"
             ];
    
}

@end

