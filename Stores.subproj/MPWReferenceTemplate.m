//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWReferenceTemplate.h"
#import <MPWFoundation/MPWFoundation.h>

typedef struct {
    BOOL isWildcard;
    NSString *segmentName;
    NSString *parameterName;
} ReferenceTemplateComponent;

typedef struct {
    int count;
    ReferenceTemplateComponent components[0];
} ReferenceTemplateComponents;

@implementation MPWReferenceTemplate
{
    ReferenceTemplateComponents *components;
}



CONVENIENCEANDINIT( propertyPath, WithReference:(id <MPWReferencing>)ref)
{
    if (self=[super init] ) {
        NSArray *pathComponents=ref.pathComponents;
        long count=pathComponents.count;
        components = calloc( sizeof(ReferenceTemplateComponents)+sizeof(ReferenceTemplateComponent)*count,1);
        components->count=count;
        for (int i=0;i<count;i++) {
            NSString *s=pathComponents[i];
            ReferenceTemplateComponent *component=&components->components[i];
            if ( [s hasPrefix:@"*"]) {
                component->isWildcard=YES;
                if ( [s hasPrefix:@"*:"]) {
                    component->parameterName=[[s substringFromIndex:2] retain];
                } else {
                    component->parameterName=nil;
                }
            } else if ( [s hasPrefix:@":"]) {
                component->parameterName=[[s substringFromIndex:1] retain];
            } else {
                component->segmentName=[s retain];
            }
        }
    } else {
        [self release];
    }
//
//    NSMutableArray *comps=[NSMutableArray array];
//    for ( NSString *s in ref.pathComponents) {
//        [comps addObject:[MPWReferenceTemplateComponent componentWithString:s]];
//    }
    return self;
}

CONVENIENCEANDINIT( propertyPath, WithPathString:(NSString*)path)
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:path];

    return [self initWithReference:ref];
}

-(NSString*)name
{
    NSMutableString *pathName=[NSMutableString string];
    for (int i=0;i<components->count;i++) {
        ReferenceTemplateComponent *c=&components->components[i];
        if ( c->isWildcard) {
            [pathName appendString:@"*"];
        }
        if ( c->parameterName) {
            [pathName appendString:@":"];
            [pathName appendString:c->parameterName];
        } else  if ( c->segmentName) {
            [pathName appendString:c->segmentName];
        }
        if ( i<components->count-1 ) {
            [pathName appendString:@"/"];
        }
    }
    return pathName;
 }

-(NSDictionary*)bindingsForMatchedReference:(id <MPWReferencing>)ref
{
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSArray *pathComponents=[ref relativePathComponents];
    long pathCount = pathComponents.count;
    BOOL isWild=NO;
    if ( pathCount > 0) {
        for (long i=0, max=MIN(pathCount,components->count);i<max;i++) {
            NSString *segment=pathComponents[i];
            ReferenceTemplateComponent *component=&components->components[i];
            NSString *matcherName=component->segmentName;
            NSString *argName=component->parameterName;
            
            if ( matcherName ) {
                if ( ![matcherName isEqualToString:segment]) {
                    return nil;
                }
            } else if ( argName) {
                if ( component->isWildcard ) {
                    isWild=YES;
                    result[argName]=[[pathComponents subarrayWithRange:NSMakeRange(i,pathComponents.count-i)] componentsJoinedByString:@"/"];
                    break;
                } else {
                    result[argName]=segment;
                }
            }
        }
    } else if ( [ref isRoot] ) {
        if ( components->count == 1) {
            if (components->components[0].isWildcard) {
                isWild=YES;
                result[@"/"]=@[@"/"];
           }
        }
    }

    if ( isWild || pathComponents.count == components->count) {
        return result;
    } else {
        return nil;
    }
}

-(NSArray*)formalParameters
{
    NSMutableArray *parameters=[NSMutableArray array];
    for ( int i=0;i<components->count;i++) {
        if ( components->components[i].parameterName ) {
            [parameters addObject:components->components[i].parameterName];
        }
    }
    return parameters;
}

-(NSDictionary*)bindingsForMatchedPath:(NSString*)path
{
    return [self bindingsForMatchedReference:[MPWGenericReference referenceWithPath:path]];
}

-(NSString*)parameterNameAtIndex:(int)i
{
    if ( components && i < components->count) {
        return components->components[i].parameterName;
    }
    return nil;
}

-(NSString*)segmentNameAtIndex:(int)i
{
    if ( components && i < components->count) {
        return components->components[i].segmentName;
    }
    return nil;
}

-(BOOL)isWildCardAtIndex:(int)i
{
    if ( components && i < components->count) {
        return components->components[i].isWildcard;
    }
    return 0;
}

-(long)count
{
    return components ? components->count : 0;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: %d pathComponents: <tbd>>",[self class],self,components->count];
}

-(void)dealloc
{
//    [_name release];
//    [_pathComponents release];
    if ( components ) {
        for (int i=0;i<components->count;i++) {
            [components->components[i].parameterName release];
            [components->components[i].segmentName release];
        }
        free(components);
    }
    [super dealloc];
}


@end


@implementation MPWReferenceTemplate(testing)


+(void)testInitializeWithSingleConstantPath
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello"];
    INTEXPECT([pp count], 1, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    
}

+(void)testInitializeWithArguments
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    INTEXPECT([pp count], 4, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    IDEXPECT([pp parameterNameAtIndex:1], @"arg1", @"arg1");
    IDEXPECT([pp segmentNameAtIndex:2], @"world", @"name");
    IDEXPECT([pp parameterNameAtIndex:3], @"arg2", @"arg2");
    
}

+(void)testInitializeWithWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/*:remainder"];
    INTEXPECT([pp count], 2, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    IDEXPECT([pp parameterNameAtIndex:1], @"remainder", @"arg1");
    EXPECTTRUE([pp isWildCardAtIndex:1], @"wildcard");
    
}

+(void)testMatchAgainstConstantPath
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/world"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/world"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,0,@"no bound vars");
    result=[pp bindingsForMatchedPath:@"h"];
    EXPECTNIL(result,@"no match");
    
}

+(void)testMatchAgainstPathWithParameters
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/this/world/cruel"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,2,@"two bound vars");
    IDEXPECT(result[@"arg1"],@"this",@"binding for arg1");
    IDEXPECT(result[@"arg2"],@"cruel",@"binding for arg2");
}

+(void)testNonMatchTooManyComponentsInProperty
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@":arg1/count"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello"];
    EXPECTNIL(result,@"no match");
}

+(void)testMatchAgainstWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/*:arg2"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/this/world/cruel/remainder"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,2,@"two bound vars");
    IDEXPECT(result[@"arg2"],@"cruel/remainder",@"binding for arg2");
    
}

+(void)testMatchRootAgainstWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"*"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"/"];
    EXPECTNOTNIL(result,@"got a match");
    
}

+(void)testListFormalParameters
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    NSArray *formalParameters=[pp formalParameters];
    
    INTEXPECT(formalParameters.count,2,@"two parameters");
    IDEXPECT(formalParameters,(@[ @"arg1", @"arg2"]),@"the parameters");
}


+testSelectors
{
    return @[
             @"testInitializeWithSingleConstantPath",
             @"testInitializeWithArguments",
             @"testInitializeWithWildcard",
             @"testMatchAgainstConstantPath",
             @"testMatchAgainstPathWithParameters",
             @"testMatchAgainstWildcard",
//             @"testMatchRootAgainstWildcard",
             @"testListFormalParameters",
             @"testNonMatchTooManyComponentsInProperty",
    ];
}

@end

