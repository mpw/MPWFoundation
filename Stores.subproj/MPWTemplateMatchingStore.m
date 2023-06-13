//
//  MPWTemplateMatchingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import "MPWTemplateMatchingStore.h"
#import "MPWReferenceTemplate.h"
#import "MPWFastInvocation.h"

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
//    NSLog(@"at: %@",aReference);
    for ( long i=0,max=self.templates.count; i<max; i++ ) {
//        NSLog(@"try template[%ld]=%@",i,self.templates[i]);
        MPWReferenceTemplate *template = self.templates[i];
        NSArray *params = [template parametersForMatchedReference:aReference];
        if ( params ) {
//            NSLog(@"match at %ld",i);
            id value = self.values[i];
//            NSLog(@"got value: %@",value);
            if ( self.useParam ) {
//                NSLog(@"use additional param: %@",self.additionalParam);
                params = [params arrayByAddingObject:self.additionalParam];
            }
            if ( self.addRef) {
                params = [params arrayByAddingObject:aReference];
            }
            if ( [value respondsToSelector:@selector(evaluateOnObject:parameters:)]) {
//                NSLog(@"will evaluate with parameters: %@",params);
                value = [value evaluateOnObject:self.target parameters:params];
//                NSLog(@"did evaluate, got new value: %@",value);
            }
            return value;
        }
    }
    return nil;
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    if ( ![aReference isKindOfClass:[MPWReferenceTemplate class]]) {
        aReference = (id)[MPWReferenceTemplate templateWithReference:aReference];
    }
    [self.templates addObject:aReference];
    [self.values addObject:theObject];
}

-(void)setContext:aContext
{
    for (id template in self.templates) {
        if ( [template respondsToSelector:@selector(setContext:)]) {
            [template setContext:aContext];
        }
    }
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
    EXPECTNIL((store[@"key/path"]),@"simple lookup of non-existent complex path");
}

+(void)testWildcardMatchesRoot
{
    MPWTemplateMatchingStore *store=[self store];
    store[@"*"]=@"value";
    IDEXPECT((store[@"/"]), @"value",@"root matched");
}

+(void)testSlashWildcardMatchesRoot
{
    MPWTemplateMatchingStore *store=[self store];
    store[@"/*"]=@"value";
    IDEXPECT((store[@"/"]), @"value",@"root matched");
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
    store[@"base/:param"]=@[];
    IDEXPECT((store[@"base/path1"]),(@[ @"path1" ]),@"simple lookup with parameterised template");
    IDEXPECT((store[@"base/path2"]),(@[@"path2"] ),@"simple lookup with different parameter");
    EXPECTNIL((store[@"base1/path2"]),@"base path is not flexible");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanMatchSimpleConstant",
       @"testCanMatchParameter",
       @"testEvaluateWithPathParamters",
//       @"testWildcardMatchesRoot",
       @"testSlashWildcardMatchesRoot",
			];
}

@end


@implementation NSArray(evaluation)

-evaluateOnObject:target parameters:params
{
    return [self arrayByAddingObjectsFromArray:params];
}

@end

