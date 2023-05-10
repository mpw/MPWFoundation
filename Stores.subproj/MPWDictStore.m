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
#import "MPWDirectoryBinding.h"

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
    NSArray *components=[ref relativePathComponents];
    return [components componentsJoinedByString:@"/"];
}

-(NSArray*)childNamesOfReference:aReference
{
    if ( [(MPWGenericReference*)aReference isRoot]) {
        return [[self dict] allKeys];
    } else {
        return @[];
    }
}

-directoryForReference:(MPWGenericReference*)aReference
{
    NSArray *refs = (NSArray*)[[self collect] referenceForPath:[[self childNamesOfReference:aReference] each]];
    return [[[MPWDirectoryBinding alloc] initWithContents:refs] autorelease];
}


-at:(id <MPWReferencing>)aReference
{
//    if ( [(MPWGenericReference*)aReference isRoot]) {
//        return [self directoryForReference:aReference];
//    } else {
        return self.dict[[self referenceToKey:aReference]];
//    }
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

-childrenOfReference:aReference
{
//    if ( [aReference isRoot]) {
        return [self.dict allKeys];
//    } else {
//        return nil;
//    }
}

-(BOOL)hasChildren:(id <MPWReferencing>)aReference
{
    if ( [(MPWGenericReference*)aReference isRoot]) {
        return YES;
    } else {
        return NO;
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

+(void)testChildrenOfReference
{
    id ref=@"World";
    MPWDictStore* store = [self store];
    NSArray *refs=[store childrenOfReference:@""];
    INTEXPECT( refs.count, 0, @"empty");
    store[ref]=@"Hello";
    refs=[store childrenOfReference:@"/"];
    INTEXPECT( refs.count, 1, @"no longer empty");
    IDEXPECT( [refs.firstObject path], ref ,@"ref");
    
}

+(void)testRootDirectory
{
    id ref=@"World";
    MPWDictStore* store = [self store];
    MPWDirectoryBinding *dir1=store[@"/"];
    INTEXPECT(dir1.count, 0, @"empty directory");
    store[ref]=@"Hello";
    MPWDirectoryBinding *dir2=store[@"/"];
    INTEXPECT(dir2.count, 1, @"directory no longer empty");
    IDEXPECT(dir2.contents.firstObject, [store referenceForPath:ref],@"contents");
}


+(NSArray<NSString*>*)testSelectors
{
    return @[
             @"testStoreAndRetrieve",
             @"testStoreAndRetrieveViaReference",
             @"testSubscripts",
             @"testDelete",
             @"testChildrenOfReference",
//             @"testRootDirectory",
             ];
}

@end
