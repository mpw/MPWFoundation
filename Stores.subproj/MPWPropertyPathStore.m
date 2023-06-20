//
//  MPWPropertyPathStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 06.06.23.
//

#import "MPWPropertyPathStore.h"
#import "MPWRESTOperation.h"


@interface MPWPropertyPathStore()

@property (nonatomic, strong)  id target;

@end


@implementation MPWPropertyPathStore
{
    MPWTemplateMatchingStore *stores[MPWRESTVerbMAX];
}

-(instancetype)init
{
    if ( self=[super init] ) {
        bzero(stores, sizeof stores);
    }
    return self;
}

-(void)createMatchers:(PropertyPathDefs*)defs
{
    MPWTemplateMatchingStore *matcher=[[MPWTemplateMatchingStore alloc] initWithPropertyPathDefs:defs];
    [stores[defs->verb] release];
    stores[defs->verb]=matcher;
}

-theTarget
{
    return self.target ?: self;
}

-(id)at:(id<MPWReferencing>)aReference
{
    return [stores[MPWRESTVerbGET] at:aReference for:self.theTarget with:&aReference count:1];
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    id extras[]={theObject,aReference};
    [stores[MPWRESTVerbPUT] at:aReference for:self.theTarget with:extras count:2];
}

-(void)at:(id<MPWReferencing>)aReference post:(id)theObject
{
    id extras[]={theObject,aReference};
    [stores[MPWRESTVerbPOST] at:aReference for:self.theTarget with:extras count:2];
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    [stores[MPWRESTVerbDELETE] at:aReference for:self.theTarget with:&aReference count:1];
}

-(void)dealloc
{
    for (int i=0;i<MPWRESTVerbMAX;i++) {
        [stores[i] release];
    }
    [_target release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWPropertyPathStore(testing) 

+(void)testPropertyPathStoreForDict
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//        @"testPropertyPathStoreForDict"
   ];
}

@end
