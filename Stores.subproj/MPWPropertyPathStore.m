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

-(void)createMatchers:(PropertyPathDef*)defs count:(int)numDefs verb:(MPWRESTVerb)verb
{
    MPWTemplateMatchingStore *matcher=[[MPWTemplateMatchingStore alloc] initWithPropertyPathDefs:defs count:numDefs];
    [stores[verb] release];
    stores[verb]=matcher;
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
    NSMutableDictionary *base=[[@{ @"hi": @"there"} mutableCopy] autorelease];
    IMP get=[base methodForSelector:@selector(at:)];
    IMP set=[base methodForSelector:@selector(at:put:)];
    MPWReferenceTemplate *t1=[MPWReferenceTemplate templateWithReference:@"get/:key"];
    MPWReferenceTemplate *t2=[MPWReferenceTemplate templateWithReference:@"set/:key"];
    PropertyPathDef getdefs[] = {
        { [t1 retain], (IMP)get, nil   },
    };
    PropertyPathDef setdefs[] = {
        { [t2 retain], (IMP)set, nil   },
    };
    MPWPropertyPathStore *store=[self store];
    [store createMatchers:getdefs count:1 verb:MPWRESTVerbGET];
    [store createMatchers:setdefs count:1 verb:MPWRESTVerbPUT];
    store.target = base;
    

    id value1=[store at:@"get/hi"];
    IDEXPECT(value1, @"there",@"function result");
    id newObject=@"theBlubVal";
    [store at:@"set/blub" put:newObject];
    IDEXPECT( base[@"blub"], @"theBlubVal", @"set was successfull");
}

+(NSArray*)testSelectors
{
   return @[
        @"testPropertyPathStoreForDict"
   ];
}

@end
