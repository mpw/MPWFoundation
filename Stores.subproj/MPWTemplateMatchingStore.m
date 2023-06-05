//
//  MPWTemplateMatchingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import "MPWTemplateMatchingStore.h"
#import "MPWReferenceTemplate.h"


@interface MPWTemplateMatchingStore()

@property (nonatomic, strong)  NSMutableArray<MPWReferenceTemplate*> *templates;
@property (nonatomic, strong)  NSMutableArray *values;

@end


@implementation MPWTemplateMatchingStore

-(instancetype)init
{
    self=[super init];
    self.templates = [NSMutableArray array];
    self.values    = [NSMutableArray array];
    return self;
}

-(id)at:(id<MPWReferencing>)aReference
{
    for ( long i=0,max=self.templates.count; i<max; i++ ) {
        MPWReferenceTemplate *template = self.templates[i];
        NSDictionary *bindings = [template bindingsForMatchedReference:aReference];
        if ( bindings ) {
            id value = self.values[i];
            if ( [value respondsToSelector:@selector(valueWithBindings:)]) {
                value = [value valueWithBindings:bindings];
            }
            return value;
        }
    }
    return nil;
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    [self.templates addObject:[MPWReferenceTemplate templateWithReference:aReference]];
    [self.values addObject:theObject];
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTemplateMatchingStore(testing) 

+(void)testCanMatchSimpleConstant
{
    MPWTemplateMatchingStore *store=[self store];
    store[@"key"]=@"value";
    IDEXPECT((store[@"key"]), @"value",@"simple lookup");
    EXPECTNIL((store[@"key1"]),@"simple lookup of non-existent key");
    EXPECTNIL((store[@"key/path"]),@"simple lookup of non-existent complex");
}

+(void)testCanMatchParameter
{
    MPWTemplateMatchingStore *store=[self store];
    store[@"base/:param"]=@"value";
    IDEXPECT((store[@"base/path1"]),@"value",@"simple lookup with parameterised template");
    IDEXPECT((store[@"base/path2"]),@"value",@"simple lookup with different parameter");
    EXPECTNIL((store[@"base1/path2"]),@"base path is not flexible");
}

+(void)testEvaluateWithPathParamters
{
    MPWTemplateMatchingStore *store=[self store];
    store[@"base/:param"]=@{};
    IDEXPECT((store[@"base/path1"]),(@{@"param": @"path1" }),@"simple lookup with parameterised template");
    IDEXPECT((store[@"base/path2"]),(@{@"param": @"path2" }),@"simple lookup with different parameter");
    EXPECTNIL((store[@"base1/path2"]),@"base path is not flexible");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanMatchSimpleConstant",
       @"testCanMatchParameter",
       @"testEvaluateWithPathParamters",
			];
}

@end

@implementation NSDictionary(evaluation)

-valueWithBindings:(NSDictionary*)bindings
{
    NSMutableDictionary *result=[self mutableCopy];
    [result addEntriesFromDictionary:bindings];
    return [result autorelease];
}

@end
