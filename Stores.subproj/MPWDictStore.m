//
//  MPWDictStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDictStore.h"
#import "MPWGenericReference.h"
#import "NSStringAdditions.h"
#import <AccessorMacros.h>

@interface MPWDictStore()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end


@implementation MPWDictStore

CONVENIENCEANDINIT( store, WithDictionary:(NSMutableDictionary*)newDict)
{
    self=[super init];
    self.dict = newDict;
    return self;
}

-(instancetype)init
{
    return [self initWithDictionary:[NSMutableDictionary dictionary]];
}

-referenceToKey:(id <MPWReferencing>)ref
{
    return [ref path];
}

-at:(id <MPWReferencing>)aReference
{
    return self.dict[[self referenceToKey:aReference]];
}

-(void)deleteAt:(id <MPWReferencing>)aReference
{
    [self.dict removeObjectForKey:[self referenceToKey:aReference]];
}

-(void)at:(id <MPWReferencing>)aReference put:theObject
{
    if ( theObject != nil ) {
        self.dict[[self referenceToKey:aReference]]=theObject;
    } else {
        [self deleteAt:aReference];
    }
}


-(void)dealloc
{
    [_dict release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWDictStore(testing)

+(void)testStoreAndRetrieve
{
    MPWDictStore* store = [self store];
    NSString *ref=@"World";
    EXPECTNIL([store at:ref], @"shouldn't be there before I store it");
    [store at:ref put:@"Hello"];
    IDEXPECT([store at:ref], @"Hello", @"should be there after I store it");
}

+(void)testStoreAndRetrieveViaReference
{
    NSString *path=@"World";
    MPWDictStore* store = [self store];
    EXPECTNIL([store at:path], @"shouldn't be there before I store it");
    [store at:path put:@"Hello"];
    IDEXPECT([store at:path], @"Hello", @"should be there after I store it");
}

+(void)testSubscripts
{
    MPWDictStore* store = [self store];
    EXPECTNIL(store[@"World"], @"shouldn't be there before I store it");
    store[@"World"]=@"Hello";
    IDEXPECT(store[@"World"], @"Hello", @"should be there after I store it");
}

+(void)testDelete
{
    MPWDictStore* store = [self store];
    id ref=@"World";
    EXPECTNIL(store[ref], @"shouldn't be there before I store it");
    store[ref]=@"Hello";
    IDEXPECT(store[ref], @"Hello", @"should be there after I store it");
    [store deleteAt:ref];
    EXPECTNIL(store[ref], @"shouldn't be there after delete");
}


+(NSArray<NSString*>*)testSelectors
{
    return @[
             @"testStoreAndRetrieve",
             @"testStoreAndRetrieveViaReference",
             @"testSubscripts",
             @"testDelete",
             ];
}

@end
