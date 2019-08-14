//
//  MPWDictStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDictStore.h"
#import "MPWGenericReference.h"
#import "NSStringAdditions.h"
#import "AccessorMacros.h"

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

-referenceToKey:(MPWReference*)ref
{
    return ref;
}

-objectForReference:(MPWReference*)aReference
{
    return self.dict[[self referenceToKey:aReference]];
}

-(void)deleteObjectForReference:(MPWReference*)aReference
{
    [self.dict removeObjectForKey:[self referenceToKey:aReference]];
}

-(void)setObject:theObject forReference:(id <MPWReferencing>)aReference
{
    if ( theObject != nil ) {
        self.dict[[self referenceToKey:(MPWReference*)aReference]]=theObject;
    } else {
        [self deleteObjectForReference:aReference];
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
    id ref=[store referenceForPath:@"World"];
    EXPECTNIL([store objectForReference:ref], @"shouldn't be there before I store it");
    [store setObject:@"Hello" forReference:ref];
    IDEXPECT([store objectForReference:ref], @"Hello", @"should be there after I store it");
}

+(void)testStoreAndRetrieveViaReference
{
    NSString *path=@"World";
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:path];
    MPWDictStore* store = [self store];
    EXPECTNIL([store objectForReference:ref], @"shouldn't be there before I store it");
    [store setObject:@"Hello" forReference:ref];
    IDEXPECT([store objectForReference:ref], @"Hello", @"should be there after I store it");
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
    id ref=[store referenceForPath:@"World"];
    EXPECTNIL(store[ref], @"shouldn't be there before I store it");
    store[ref]=@"Hello";
    IDEXPECT(store[ref], @"Hello", @"should be there after I store it");
    [store deleteObjectForReference:ref];
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
