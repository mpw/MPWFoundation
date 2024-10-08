//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWReferenceTemplate.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWReferenceTemplate
{
    ReferenceTemplateComponents *components;
    NSArray *formalParameters;
    int parameterCount;
}

-(int)parameterCount
{
    return parameterCount;
}

lazyAccessor(NSArray*, formalParameters, setFormalParamters, createFormalParameters)

ReferenceTemplateComponents* componentsFromReference( id <MPWIdentifying> ref )
{
    NSArray *pathComponents=ref.pathComponents;
    long count=pathComponents.count;
    ReferenceTemplateComponents* components = calloc( sizeof(ReferenceTemplateComponents)+sizeof(ReferenceTemplateComponent)*count,1);
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
    return components;
}

-initWithComponents:(ReferenceTemplateComponents*)newComponents
{
    if (self=[super init]) {
        components=newComponents;
        int paramCount=0;
        for (int i=0;i<newComponents->count;i++) {
            if ( newComponents->components[i].parameterName) {
                paramCount++;
            }
        }
        parameterCount=paramCount;
    }
    return self;
}

CONVENIENCEANDINIT( template, WithReference:(id <MPWIdentifying>)ref)
{
    return [self initWithComponents:componentsFromReference(ref)];
}

CONVENIENCEANDINIT( template, WithString:(NSString*)path)
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:path];

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



-(BOOL)getParameters:(NSString **)params  forMatchedReference:(id <MPWIdentifying>)ref
{
//    NSLog(@"getParameters:forMatchedReference: %@/%@",[ref class],ref);
    int currentParam=0;
    NSArray *pathComponents=[ref relativePathComponents];
    BOOL hasTrailingSlash=[ref hasTrailingSlash];
    long pathCount = pathComponents.count;
    BOOL isWild=NO;
   long componentCount = components->count;
    if ( pathCount > 0 ) {
//        NSLog(@"have path components in path: %ld in matcher: %ld ",pathCount,componentCount);
        for (long i=0, max=MIN(pathCount,components->count);i<max;i++) {
            NSString *segment=pathComponents[i];
            ReferenceTemplateComponent *component=&components->components[i];
            NSString *matcherName=component->segmentName;
            NSString *argName=component->parameterName;
            NSString *nextMatch=nil;
            
            if ( matcherName ) {
//               NSLog(@"try to match name: %@ to segment: %@",matcherName,segment);
                if ( ![matcherName isEqualToString:segment]) {
                    return NO;
                }
            } else if ( argName && !component->isWildcard) {
                nextMatch=segment;
            } else if ( component->isWildcard) {
                isWild=YES;
                if ( argName ) {
                    nextMatch=[[pathComponents subarrayWithRange:NSMakeRange(i,pathComponents.count-i)] componentsJoinedByString:@"/"];
                   if ( hasTrailingSlash ) {
                      nextMatch = [nextMatch stringByAppendingString:@"/"];
                   }
                }
            }
            if (nextMatch) {
                params[currentParam++]=nextMatch;
                nextMatch=nil;
            }
        }
       if ( hasTrailingSlash) {
          pathCount++;
       }
//       NSLog(@"at end of match loop");
       if ( componentCount == pathCount && hasTrailingSlash ) {
          // match a trailing slash with a wildcard
          ReferenceTemplateComponent *component=&components->components[componentCount-1];
          if ( component->isWildcard ) {
             params[currentParam++]=@"";
          }
       }
    } else if ( [ref isRoot] || componentCount==0) {
//        NSLog(@"incoming isRoot");
        if ( components->count >= 1) {
//            NSLog(@"isRoot");
            if (components->components[0].isWildcard) {
                isWild=YES;
            }
        }
    }
    
    if ( isWild || pathCount == componentCount) {
        return YES;
    } else {
        return NO;
    }
}

-(NSArray*)parametersForMatchedReference:(id <MPWIdentifying>)ref
{
    NSString *params[parameterCount+1];
    if ( [self getParameters:params forMatchedReference:ref] ) {
        return [NSArray arrayWithObjects:params count:parameterCount];
    } else {
        return nil;
    }
    
}

-(NSDictionary*)bindingsForMatchedReference:(id <MPWIdentifying>)ref
{
    NSArray *matches = [self parametersForMatchedReference:ref];
    if ( matches ) {
        NSArray *parameters=[self formalParameters];
        if (parameters.count != matches.count){
            NSLog(@"mismatch, formal: %@  matched: %@ ref: %@  template: %@",
                  parameters,matches,ref,self);
        }
        return [NSDictionary dictionaryWithObjects:matches forKeys:self.formalParameters];
    } else {
        return nil;
    }
}


-(NSArray*)createFormalParameters
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
    return [self bindingsForMatchedReference:[MPWGenericIdentifier referenceWithPath:path]];
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
    return [NSString stringWithFormat:@"<%@:%p: %ld pathComponents: %@>",[self class],self,components->count,[self name]];
}

-(void)dealloc
{
    if ( components ) {
        for (int i=0;i<components->count;i++) {
            [components->components[i].parameterName release];
            [components->components[i].segmentName release];
        }
        free(components);
    }
    [super dealloc];
}

-(NSString *)stringValue
{
    return [self name];
}


@end


@implementation NSObject(asReferenceTemplate)

-asReferenceTemplate
{
   return [MPWReferenceTemplate templateWithReference:[self stringValue]];
}

@end

@implementation NSString(asReferenceTemplate)

-asReferenceTemplate
{
   return [MPWReferenceTemplate templateWithReference:self];
}

@end

@implementation MPWReferenceTemplate(asReferenceTemplate)

-asReferenceTemplate
{
   return self;
}

@end


@implementation MPWIdentifier(asReferenceTemplate)

-asReferenceTemplate
{
   return [MPWReferenceTemplate templateWithReference:self];
}

@end


@implementation MPWReferenceTemplate(testing)


+(void)testInitializeWithSingleConstantPath
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello"];
    INTEXPECT([pp count], 1, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    
}

+(void)testInitializeWithArguments
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/:arg1/world/:arg2"];
    INTEXPECT([pp count], 4, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    IDEXPECT([pp parameterNameAtIndex:1], @"arg1", @"arg1");
    IDEXPECT([pp segmentNameAtIndex:2], @"world", @"name");
    IDEXPECT([pp parameterNameAtIndex:3], @"arg2", @"arg2");
    
}

+(void)testInitializeWithWildcard
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/*:remainder"];
    INTEXPECT([pp count], 2, @"number of components")
    IDEXPECT([pp segmentNameAtIndex:0], @"hello", @"name");
    IDEXPECT([pp parameterNameAtIndex:1], @"remainder", @"arg1");
    EXPECTTRUE([pp isWildCardAtIndex:1], @"wildcard");
    
}

+(void)testMatchAgainstConstantPath
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/world"];
    NSArray *result=[pp parametersForMatchedReference:@"hello/world"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,0,@"no bound vars");
    result=[pp parametersForMatchedReference:@"h"];
    EXPECTNIL(result,@"no match");
    
}

+(void)testMatchAgainstPathWithParameters
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/:arg1/world/:arg2"];
    NSArray *result=[pp parametersForMatchedReference:@"hello/this/world/cruel"];
    INTEXPECT(result.count,2,@"two bound vars");
    
    IDEXPECT(result[0],@"this",@"binding for arg1");
    IDEXPECT(result[1],@"cruel",@"binding for arg2");
}

+(void)testMatchAgainstPathWithParametersReturningBindings
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/:arg1/world/:arg2"];
    NSDictionary *result=[pp bindingsForMatchedReference:@"hello/this/world/cruel"];
    INTEXPECT(result.count,2,@"two bound vars");
    
    IDEXPECT(result[@"arg1"],@"this",@"binding for arg1");
    IDEXPECT(result[@"arg2"],@"cruel",@"binding for arg2");
}

+(void)testNonMatchTooManyComponentsInProperty
{
    MPWReferenceTemplate *pp=[self templateWithString:@":arg1/count"];
    NSArray *result=[pp parametersForMatchedReference:@"hello"];
    EXPECTNIL(result,@"no match");
}

+(void)testMatchAgainstWildcard
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/:arg1/world/*:arg2"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/this/world/cruel/remainder"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,2,@"two bound vars");
    IDEXPECT(result[@"arg2"],@"cruel/remainder",@"binding for arg2");
}

+(void)testMatchPathWithSlashAtEndAgainstWildcard
{
   MPWReferenceTemplate *pp=[self templateWithString:@"hello/*:arg2"];
   NSDictionary *result=[pp bindingsForMatchedPath:@"hello/slash/"];
   EXPECTNOTNIL(result,@"got a match");
   INTEXPECT(result.count,1,@"one bound var");
   IDEXPECT(result[@"arg2"],@"slash/",@"binding for arg2");
}

+(void)testMatchPathWithOnlyTheSlashAtEndAgainstWildcard
{
   MPWReferenceTemplate *pp=[self templateWithString:@"hello/*:arg2"];
   NSDictionary *result=[pp bindingsForMatchedPath:@"hello/"];
   EXPECTNOTNIL(result,@"got a match");
   INTEXPECT(result.count,1,@"one bound vars");
   IDEXPECT(result[@"arg2"],@"",@"binding for arg2");
   NSDictionary *resultWithoutSlash=[pp bindingsForMatchedPath:@"hello"];
   EXPECTNIL(resultWithoutSlash, @"should no match");
}

+(void)testPathWithSlashShouldNotMatchTemplateWithout
{
   MPWReferenceTemplate *pp=[self templateWithString:@"hello"];
   NSDictionary *result=[pp bindingsForMatchedPath:@"hello/"];
   EXPECTNIL(result,@"should not match");
}

+(void)testMatchRootAgainstWildcard
{
    MPWReferenceTemplate *pp=[self templateWithString:@"*"];
    NSArray *result=[pp parametersForMatchedReference:@"/"];

    EXPECTNOTNIL(result,@"got a match");
}

+(void)testMatchEmptyAgainstWildcard
{
    MPWReferenceTemplate *pp=[self templateWithString:@"*"];
    NSDictionary *result=[pp bindingsForMatchedPath:@""];
    EXPECTNOTNIL(result,@"got a match");
}

+(void)testListFormalParameters
{
    MPWReferenceTemplate *pp=[self templateWithString:@"hello/:arg1/world/:arg2"];
    NSArray *formalParameters=[pp formalParameters];
    
    INTEXPECT(formalParameters.count,2,@"two parameters");
    IDEXPECT(formalParameters,(@[ @"arg1", @"arg2"]),@"the parameters");
}

+(void)testListFormalParametersForWildcard
{
    MPWReferenceTemplate *pp=[self templateWithString:@"*"];
    NSArray *formalParameters=[pp formalParameters];
    
    INTEXPECT(formalParameters.count,0,@"no parameters specified");
}

+(void)testListFormalParametersForWildcardWithArgname
{
    MPWReferenceTemplate *pp=[self templateWithString:@"*:rest"];
    NSArray *formalParameters=[pp formalParameters];
    
    INTEXPECT(formalParameters.count,1,@"no parameters specified");
    IDEXPECT(formalParameters,(@[ @"rest"]),@"the parameters");
}


+testSelectors
{
    return @[
             @"testInitializeWithSingleConstantPath",
             @"testInitializeWithArguments",
             @"testInitializeWithWildcard",
             @"testMatchAgainstConstantPath",
             @"testMatchAgainstPathWithParameters",
             @"testMatchAgainstPathWithParametersReturningBindings",
             @"testMatchAgainstWildcard",
             @"testMatchPathWithSlashAtEndAgainstWildcard",
             @"testPathWithSlashShouldNotMatchTemplateWithout",
             @"testMatchPathWithOnlyTheSlashAtEndAgainstWildcard",
             @"testMatchRootAgainstWildcard",
             @"testMatchEmptyAgainstWildcard",
             @"testListFormalParameters",
             @"testListFormalParametersForWildcard",
             @"testListFormalParametersForWildcardWithArgname",
             @"testNonMatchTooManyComponentsInProperty",
    ];
}

@end

