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

-(id)at:(id<MPWReferencing>)aReference for:target with:(id*)extraParams count:(int)extraParamCount
{
    id params[100];
    for ( long i=0,max=self.templates.count; i<max; i++ ) {
        MPWReferenceTemplate *template = self.templates[i];
        if ( [template getParameters:params forMatchedReference:aReference] ) {
            int numParams = template.parameterCount;
            for (int j=0;j<extraParamCount;j++) {
                params[numParams+j]=extraParams[j];
            }
            id value = self.values[i];
            NSArray *paramArray = [NSArray arrayWithObjects:params count:numParams+extraParamCount];
            if ( [value respondsToSelector:@selector(evaluateOnObject:parameters:)]) {
                //                NSLog(@"will evaluate with parameters: %@",params);
                value = [value evaluateOnObject:target parameters:paramArray];
                //                NSLog(@"did evaluate, got new value: %@",value);
            }
            return value;
        }
    }
    return nil;
}


-(id)at:(id<MPWReferencing>)aReference
{
    id extraParams[1]={NULL};
    return [self at:aReference for:self.target with:extraParams count:0];
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

