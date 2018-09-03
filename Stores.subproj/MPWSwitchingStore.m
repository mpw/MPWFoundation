//
//  MPWSwitchingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/18.
//

#import "MPWSwitchingStore.h"

@implementation MPWSwitchingStore

CONVENIENCEANDINIT( store, WithStoreDictionary:(NSDictionary*)newDict)
{
    return [super initWithDictionary:(NSMutableDictionary*)newDict];
}


-referenceToKey:(MPWGenericReference*)ref
{
    return [ref pathComponents][0];
}

-(MPWAbstractStore*)storeForReference:(MPWGenericReference*)aReference
{
    return [super objectForReference:aReference];
}

-objectForReference:(MPWGenericReference*)aReference
{
    return [[self storeForReference:aReference] objectForReference:aReference];
}

-(void)setObject:theObject forReference:(MPWGenericReference*)aReference
{
    [[self storeForReference:aReference] setObject:theObject forReference:aReference];
}

-(void)mergeObject:theObject forReference:(MPWGenericReference*)aReference
{
    [[self storeForReference:aReference] mergeObject:theObject forReference:aReference];
}

-(void)deleteObjectForReference:(MPWGenericReference*)aReference
{
    [[self storeForReference:aReference] deleteObjectForReference:aReference];
}


@end

@implementation MPWSwitchingStore(testing)

+(void)testSwitchingOnReference
{
    MPWDictStore *store1=[MPWDictStore store];
    MPWDictStore *store2=[MPWDictStore store];
    MPWGenericReference *ref1=[MPWGenericReference referenceWithPath:@"hi/there"];
    MPWGenericReference *ref2=[MPWGenericReference referenceWithPath:@"hey/there"];

    store1[ref1]=@"value1";
    store2[ref2]=@"value2";
    
    MPWSwitchingStore *switcher=[self storeWithStoreDictionary:@{
                                                     @"hi": store1,
                                                     @"hey": store2,
                                                     }];
    EXPECTNIL( store1[ref2],@"ref2 not in store1");
    EXPECTNIL( store2[ref1],@"ref2 not in store1");
    
    IDEXPECT( switcher[ref1], @"value1", @"switcher has ref1");
    IDEXPECT( switcher[ref2], @"value2", @"switcher has ref2");


}

+(NSArray*)testSelectors
{
    return @[
             @"testSwitchingOnReference",
             ];
}

@end
