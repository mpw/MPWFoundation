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

-(instancetype)initWithPropertyPathDefs:(PropertyPathDef *)newDefs count:(int)count
{
    self=[super init];
    [self addPropertyPathDefs:newDefs count:count];
    return self;
}


-(id)at:(id<MPWReferencing>)aReference for:target with:(id*)extraParams count:(int)extraParamCount
{
    id params[100];
    
    for ( long i=0; i<count; i++ ) {
        PropertyPathDef *def=&defs[i];
        if ( [def->propertyPath getParameters:params forMatchedReference:aReference] ) {
            id value = nil;
            int numParams = def->propertyPath.parameterCount;
            int totalParams = numParams + extraParamCount;
            for (int j=0;extraParams && j<extraParamCount;j++) {
                params[numParams+j]=extraParams[j];
            }
            if ( def->function) {
                switch ( totalParams ) {
                        
                    case 1:
                        value = ((IMP1)(def->function))( target, _cmd, params[0]);
                        break;
                    case 2:
                        NSLog(@"target: %@ arg0=%@ arg1=%@",target,params[0],params[1]);
                        value = ((IMP2)(def->function))( target, _cmd, params[0],params[1]);
                        break;
                    case 3:
                        NSLog(@"target: %@ arg0=%@ arg1=%@ arg2=%@",target,params[0],params[1],params[2]);
                        value = ((IMP3)(def->function))( target, _cmd, params[0],params[1],params[2]);
                        break;
                    default:
                        [NSException raise:@"unsupported" format:@"template matcher function with %d total arguments not support for %@",totalParams,aReference];

                }
            } else {
                value = def->method;
                NSArray *paramArray = [NSArray arrayWithObjects:params count:numParams+extraParamCount];
                if ( [value respondsToSelector:@selector(evaluateOnObject:parameters:)]) {
                    //                NSLog(@"will evaluate with parameters: %@",params);
                    value = [value evaluateOnObject:target parameters:paramArray];
                    //                NSLog(@"did evaluate, got new value: %@",value);
                }
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
    if ( defs ) {
        for (int i=0;i<count;i++) {
            [defs[i].propertyPath release];
            [defs[i].method release];
        }
        free(defs);
    }
    [super dealloc];
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

static id matchedMethod( id self, SEL _cmd, NSString *matched1, id ref )
{
    return [@"Matching Functions says hello to: " stringByAppendingString:matched1];
}

+(void)testEvaluateFunction
{
    PropertyPathDef defs[] = {
        { [[MPWReferenceTemplate templateWithReference:@"base/:param"] retain], (IMP)matchedMethod, nil   },
    };
    MPWTemplateMatchingStore *store=[self store];
    [store addPropertyPathDefs:defs count:1];
    id value=[store at:@"base/Marcel"];
    IDEXPECT(value, @"Matching Functions says hello to: Marcel",@"function result");
    
}

+(void)testEvaluateFunctionOnObjectWithAdditionalParams
{
    NSMutableDictionary *base=[[@{ @"hi": @"there"} mutableCopy] autorelease];
    IMP get=[base methodForSelector:@selector(at:)];
    IMP set=[base methodForSelector:@selector(at:put:)];
    MPWReferenceTemplate *t1=[MPWReferenceTemplate templateWithReference:@"get/:key"];
    MPWReferenceTemplate *t2=[MPWReferenceTemplate templateWithReference:@"set/:key"];
    PropertyPathDef defs[] = {
        { [t1 retain], (IMP)get, nil   },
        { [t2 retain], (IMP)set, nil   },
    };
    MPWTemplateMatchingStore *store=[[[self alloc] initWithPropertyPathDefs:defs count:2] autorelease];
    id value1=[store at:@"get/hi" for:base with:nil count:0];
    IDEXPECT(value1, @"there",@"function result");
    id newObject=@"theBlubVal";
    [store at:@"set/blub" for:base with:&newObject count:1];
    IDEXPECT( base[@"blub"], @"theBlubVal", @"set was successfull");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanMatchSimpleConstant",
       @"testCanMatchParameter",
       @"testEvaluateWithPathParamters",
       @"testWildcardMatchesRoot",
       @"testSlashWildcardMatchesRoot",
       @"testEvaluateFunction",
       @"testEvaluateFunctionOnObjectWithAdditionalParams",
			];
}

@end


@implementation NSArray(evaluation)

-evaluateOnObject:target parameters:params
{
    return [self arrayByAddingObjectsFromArray:params];
}

@end

