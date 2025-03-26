//
//  MPWPropertyPathStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 06.06.23.
//

#import "MPWPropertyPathStore.h"
#import "MPWRESTOperation.h"
#import "NSObjectAdditions.h"
#import <strings.h>

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

-(id)at:(id<MPWIdentifying>)aReference verb:(MPWRESTVerb)verb for:target with:(id*)args count:(int)count
{
    return [stores[verb] at:aReference for:target with:args count:count];
}


-(id)at:(id<MPWIdentifying>)aReference
{
    return [self at:aReference verb:MPWRESTVerbGET for:self.theTarget with:&aReference count:1];
}

-(void)at:(id<MPWIdentifying>)aReference put:(id)theObject
{
    id extras[]={theObject,aReference};
    [self at:aReference verb:MPWRESTVerbPUT for:self.theTarget with:extras count:2];
}

-(void)at:(id<MPWIdentifying>)aReference post:(id)theObject
{
    id extras[]={theObject,aReference};
    [self at:aReference verb:MPWRESTVerbPOST for:self.theTarget with:extras count:2];
}

-(void)deleteAt:(id<MPWIdentifying>)aReference
{
    [self at:aReference verb:MPWRESTVerbDELETE for:self.theTarget with:&aReference count:1];
}

-(void)dealloc
{
    for (int i=0;i<MPWRESTVerbMAX;i++) {
        [stores[i] release];
    }
    [_target release];
    [super dealloc];
}

void installPropertyPathsOnClass( Class targetClass, PropertyPathDef* getters,int getterCount ,PropertyPathDef* setters, int setterCount ) {
    
    MPWPropertyPathStore *store=[[MPWPropertyPathStore store] retain];
    [store createMatchers:getters count:getterCount verb:MPWRESTVerbGET];
    [store createMatchers:setters count:setterCount verb:MPWRESTVerbPUT];
    id atBlock = ^(id self, id aReference ){
        return [store at:aReference verb:MPWRESTVerbGET for:self with:&aReference count:1];
    };
    
    id atPutBlock = ^(id self, id aReference, id value ){
        id extras[2]={ value, aReference };
        [store at:aReference verb:MPWRESTVerbPUT for:self with:extras count:2];
    };
    [targetClass installIMP:imp_implementationWithBlock(atBlock) withSignature:"@:@" selector:@selector(at:) oldIMP:NULL];
    [targetClass installIMP:imp_implementationWithBlock(atPutBlock) withSignature:"@:@@" selector:@selector(at:put:) oldIMP:NULL];
}


@end


@interface MPWPropertyPathStoreTargetTestClass1 : NSObject
{
}
@property (nonatomic,strong ) id value;
@end
@interface MPWPropertyPathStoreTargetTestClass1(dynamic)
-at:key;
-(void)at:key put:value;
@end

@implementation MPWPropertyPathStoreTargetTestClass1




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
    store[@"set/blub"]=newObject;
    IDEXPECT( base[@"blub"], @"theBlubVal", @"set was successfull");
}

+(void)testConstructPropertyPathStoreAndAttachToClass
{
    MPWPropertyPathStoreTargetTestClass1 *t=[MPWPropertyPathStoreTargetTestClass1 new];
    IMP get=[t methodForSelector:@selector(value)];
    IMP set=[t methodForSelector:@selector(setValue:)];
    MPWReferenceTemplate *t1=[MPWReferenceTemplate templateWithReference:@"get"];
    MPWReferenceTemplate *t2=[MPWReferenceTemplate templateWithReference:@"set"];
    PropertyPathDef getdefs[] = {
        { [t1 retain], (IMP)get, nil   },
    };
    PropertyPathDef setdefs[] = {
        { [t2 retain], (IMP)set, nil   },
    };
    installPropertyPathsOnClass( t.class, getdefs,1 ,setdefs, 1 );
    
    t.value=@"Hi";
    id value1=[t at:@"get"];
    IDEXPECT(value1, @"Hi",@"function result");
    id newObject=@"theBlubVal";
    [t at:@"set" put:newObject];
    IDEXPECT( t.value, @"theBlubVal", @"set was successfull");
}

+(void)testTrailingSlashMatersForPropertyPathStore
{
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testPropertyPathStoreForDict",
//       @"testTrailingSlashMatersForPropertyPathStore",
       @"testConstructPropertyPathStoreAndAttachToClass",
   ];
}

@end
