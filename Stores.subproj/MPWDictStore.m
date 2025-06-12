//
//  MPWDictStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDictStore.h"
#import "MPWGenericIdentifier.h"
#import "NSStringAdditions.h"
#import <AccessorMacros.h>
#import "MPWDirectoryReference.h"
#import "MPWEnumFilter.h"

@interface MPWRawDictStore()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation MPWRawDictStore

@dynamic dict;

CONVENIENCEANDINIT( store, WithDictionary:(NSMutableDictionary*)newDict)
{
    self=[super init];
    self.dict = newDict;
    return self;
}

-(void)setDict:(NSMutableDictionary *)dict
{
    [self setBaseObject:dict];
}

-dict
{
    return self.baseObject;
}

-(instancetype)init
{
    return [self initWithDictionary:[NSMutableDictionary dictionary]];
}

-referenceToKey:(id <MPWIdentifying>)ref
{
    NSArray *components=[ref relativePathComponents];
    return [components componentsJoinedByString:@"/"];
}

-(NSArray*)childNamesOfReference:aReference
{
    if ( [(MPWGenericIdentifier*)aReference isRoot]) {
        return [[self dict] allKeys];
    } else {
        return @[];
    }
}


-at:(id <MPWIdentifying>)aReference
{
    return self.dict[[self referenceToKey:aReference]];
}

-(void)deleteAt:(id <MPWIdentifying>)aReference
{
    [self.dict removeObjectForKey:[self referenceToKey:aReference]];
}

-(void)at:(id <MPWIdentifying>)aReference put:theObject
{
    if ( theObject != nil ) {
        self.dict[[self referenceToKey:aReference]]=theObject;
    } else {
        [self deleteAt:aReference];
    }
}

-(BOOL)hasChildren:(id <MPWIdentifying>)aReference
{
    return NO;
}

-childrenOfReference:aReference
{
    return [self.dict allKeys];
}

-(void)dealloc
{
    [super dealloc];
}


@end

@implementation MPWDictStore

-directoryForReference:(MPWGenericIdentifier*)aReference
{
    NSArray *refs = (NSArray*)[[self collect] referenceForPath:[[self childNamesOfReference:aReference] each]];
    return [[[MPWDirectoryReference alloc] initWithContents:refs] autorelease];
}


-at:(id <MPWIdentifying>)aReference
{
    if ( [(MPWGenericIdentifier*)aReference isRoot]) {
        return [self directoryForReference:aReference];
    } else {
        return [super at:aReference];
    }
}



-(BOOL)hasChildren:(id <MPWIdentifying>)aReference
{
    if ( [(MPWGenericIdentifier*)aReference isRoot]) {
        return YES;
    } else {
        return [super hasChildren:aReference];
    }
}



@end

#import "DebugMacros.h"

@implementation MPWRawDictStore(testing)

+(void)testStoreAndRetrieve
{
    MPWRawDictStore* store = [self store];
    NSString *ref=@"World";
    EXPECTNIL([store at:ref], @"shouldn't be there before I store it");
    [store at:ref put:@"Hello"];
    IDEXPECT([store at:ref], @"Hello", @"should be there after I store it");
}

+(void)testStoreAndRetrieveViaReference
{
    NSString *path=@"World";
    MPWRawDictStore* store = [self store];
    EXPECTNIL([store at:path], @"shouldn't be there before I store it");
    [store at:path put:@"Hello"];
    IDEXPECT([store at:path], @"Hello", @"should be there after I store it");
}

+(void)testSubscripts
{
    MPWRawDictStore* store = [self store];
    EXPECTNIL(store[@"World"], @"shouldn't be there before I store it");
    store[@"World"]=@"Hello";
    IDEXPECT(store[@"World"], @"Hello", @"should be there after I store it");
}

+(void)testDelete
{
    MPWRawDictStore* store = [self store];
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
    MPWRawDictStore* store = [self store];
    NSArray *refs=[store childrenOfReference:@""];
    INTEXPECT( refs.count, 0, @"empty");
    store[ref]=@"Hello";
    refs=[store childrenOfReference:@"/"];
    INTEXPECT( refs.count, 1, @"no longer empty");
    IDEXPECT( [refs.firstObject path], ref ,@"ref");
    
}

+(NSArray<NSString*>*)testSelectors
{
    return @[
        @"testStoreAndRetrieve",
        @"testStoreAndRetrieveViaReference",
        @"testSubscripts",
        @"testDelete",
        @"testChildrenOfReference",
    ];
}

@end

@implementation MPWDictStore(testing)

+(void)testRootDirectoryCanBeListed
{
    id ref=@"World";
    MPWDictStore* store = [self store];
    MPWDirectoryReference *dir1=store[@"/"];
    INTEXPECT(dir1.count, 0, @"empty directory");
    store[ref]=@"Hello";
    MPWDirectoryReference *dir2=store[@"/"];
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
             @"testRootDirectoryCanBeListed",
             ];
}

@end
