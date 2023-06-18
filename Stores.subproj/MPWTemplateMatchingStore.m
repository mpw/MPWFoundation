//
//  MPWTemplateMatchingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import "MPWTemplateMatchingStore.h"
#import "MPWReferenceTemplate.h"
#import "MPWFastInvocation.h"


@implementation MPWTemplateMatchingStore
{
    PropertyPathDef *defs;
    int count;
    int max;
}

-(void)addPropertyPathDefs:(PropertyPathDef*)additionalDefs count:(int)newCount
{
    int newTotalCount = newCount + count;
    if ( newTotalCount > max )  {
        int newMax = newTotalCount * 2 + 10;
        PropertyPathDef *newDefs=calloc( newMax , sizeof(PropertyPathDef));
        if ( defs && newDefs) {
            memcpy( newDefs, defs, count * sizeof(PropertyPathDef) );
        }
        max=newMax;
        defs=newDefs;
    }
    memcpy( defs+count, additionalDefs, newCount * sizeof(PropertyPathDef) );
    count=newTotalCount;
}

-(instancetype)initWithPropertyPathDefs:(PropertyPathDefs *)newDefs
{
    self=[super init];
    [self addPropertyPathDefs:newDefs->defs count:newDefs->count];
    return self;
}

-(id)at:(id<MPWReferencing>)aReference for:target with:(id*)extraParams count:(int)extraParamCount
{
    id params[100];
    
    for ( long i=0,max=count; i<max; i++ ) {
        PropertyPathDef *def=&defs[i];
        if ( [def->propertyPath getParameters:params forMatchedReference:aReference] ) {
            int numParams = def->propertyPath.parameterCount;
            for (int j=0;extraParams && j<extraParamCount;j++) {
                params[numParams+j]=extraParams[j];
            }
            id value = def->method;
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
    MPWReferenceTemplate *template = (MPWReferenceTemplate*)aReference;
    if ( ![template isKindOfClass:[MPWReferenceTemplate class]]) {
        template = [MPWReferenceTemplate templateWithReference:aReference];
    }
    PropertyPathDef def = {
        [template retain], NULL, [theObject retain]
    };
    [self addPropertyPathDefs:&def count:1];
//    [self.templates addObject:template];
//    [self.values addObject:theObject];
}

-(void)setContext:aContext
{
    for (int i=0;i<count;i++) {
        id template=defs[i].propertyPath;
        if ( [template respondsToSelector:@selector(setContext:)]) {
            [template setContext:aContext];
        }
    }
}

-(void)dealloc
{
    
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
       @"testWildcardMatchesRoot",
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

