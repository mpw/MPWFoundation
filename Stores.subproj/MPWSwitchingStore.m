//
//  MPWSwitchingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/18.
//

#import "MPWSwitchingStore.h"
#import <AccessorMacros.h>
#import "MPWGenericIdentifier.h"

@implementation MPWSwitchingStore

CONVENIENCEANDINIT( store, WithStoreDictionary:(NSDictionary*)newDict)
{
    return [super initWithDictionary:(NSMutableDictionary*)newDict];
}


-referenceToKey:(MPWGenericIdentifier*)ref
{
    return [ref pathComponents][0];
}

-(MPWAbstractStore*)storeForReference:(MPWGenericIdentifier*)aReference
{
    return [super at:aReference];
}

-at:(MPWGenericIdentifier*)aReference
{
    return [[self storeForReference:aReference] at:aReference];
}

-(void)at:(MPWGenericIdentifier*)aReference put:theObject
{
    [[self storeForReference:aReference] at:aReference put:theObject];
}

-(void)merge:theObject at:(MPWGenericIdentifier*)aReference
{
    [[self storeForReference:aReference] merge:theObject at:aReference];
}

-(void)deleteAt:(MPWGenericIdentifier*)aReference
{
    [[self storeForReference:aReference] deleteAt:aReference];
}


@end

#import "DebugMacros.h"

@implementation MPWSwitchingStore(testing)

+(void)testSwitchingOnReference
{
    MPWDictStore *store1=[MPWDictStore store];
    MPWDictStore *store2=[MPWDictStore store];
    MPWGenericIdentifier *ref1=[MPWGenericIdentifier referenceWithPath:@"hi/there"];
    MPWGenericIdentifier *ref2=[MPWGenericIdentifier referenceWithPath:@"hey/there"];

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
