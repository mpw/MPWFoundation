//
//  MPWDictStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWDictStore.h"

@interface MPWDictStore()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end


@implementation MPWDictStore

-(instancetype)init
{
    self=[super init];
    self.dict=[NSMutableDictionary dictionary];
    return self;
}

-referenceToKey:(MPWReference*)ref
{
    return ref;
}

-objectForReference:(MPWReference*)aReference
{
    return self.dict[[self referenceToKey:aReference]];
}

-(void)setObject:theObject forReference:(MPWReference*)aReference
{
    self.dict[[self referenceToKey:aReference]]=theObject;
}
-(void)deleteObjectForReference:(MPWReference*)aReference
{
    self.dict[[self referenceToKey:aReference]]=nil;
}

@end

#import "DebugMacros.h"

@implementation MPWDictStore(testing)

+(void)testStoreAndRetrieve
{
    MPWDictStore* store = [self store];
    EXPECTNIL([store objectForReference:@"World"], @"shouldn't be there before I store it");
    [store setObject:@"Hello" forReference:@"World"];
    IDEXPECT([store objectForReference:@"World"], @"Hello", @"should be there after I store it");
}

+(void)testSubscripts
{
    MPWDictStore* store = [self store];
    EXPECTNIL(store[@"World"], @"shouldn't be there before I store it");
    store[@"World"]=@"Hello";
    IDEXPECT(store[@"World"], @"Hello", @"should be there after I store it");
}


+(NSArray<NSString*>*)testSelectors
{
    return @[
             @"testStoreAndRetrieve",
             @"testSubscripts",
             ];
}

@end
