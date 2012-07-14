//
//  MPWValueAccessor.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWValueAccessor.h"
#import "AccessorMacros.h"
#import <Foundation/Foundation.h>
#import <MPWFoundation/MPWByteStream.h>
#import <objc/runtime.h>


@implementation MPWValueAccessor

idAccessor(target, _setTarget)

extern id objc_msgSend(id, SEL, ...);

+valueForName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}

-(void)setName:(NSString*)name forComponent:(AccessPathComponent*)component
{
    component->getSelector= NSSelectorFromString(name);
    component->putSelector=NSSelectorFromString([[@"set" stringByAppendingString:[name capitalizedString]] stringByAppendingString:@":"]);
    component->getIMP=objc_msgSend;
    component->putIMP=objc_msgSend;
    component->targetOffset=-1;
    component->additionalArg=[name retain];
}

-(void)bindComponent:(AccessPathComponent*)component toTarget:aTarget
{
    component->targetClass=object_getClass( aTarget);
    component->getIMP=[aTarget methodForSelector:component->getSelector];
    component->putIMP=[aTarget methodForSelector:component->putSelector];
    if ( (component->getIMP == NULL) || (component->putIMP == NULL) ) {
        [NSException raise:@"bind failed" format:@"bind failed"];
    }
}

-(void)setComponentsForPath:(NSArray*)pathComponents
{
    int componentCount=[pathComponents count];
    NSAssert1(componentCount<6, @"only support up to 6 path components got %d", componentCount);
    count=componentCount;
    for (int i=0;i<count;i++) {
        [self setName:[pathComponents objectAtIndex:i] forComponent:components+i];
    }
}

-initWithPath:(NSString*)path
{
    self=[super init];
    if ( self ) {
        [self setComponentsForPath:[path componentsSeparatedByString:@"/"]];
    }
    return self;
}

-initWithName:(NSString*)name
{
    return [self initWithPath:name];
}


static inline id getValueForComponents( id currentTarget, AccessPathComponent *c , int count) {
    for (int i=0;i<count;i++) {
        currentTarget=c[i].getIMP( currentTarget, c[i].getSelector, c[i].additionalArg );
    }
    return currentTarget;
}

static inline void setValueForComponents( id currentTarget, AccessPathComponent *c , int count, id value) {
    currentTarget = getValueForComponents( currentTarget, c, count-1);
    int final=count-1;
    c[final].putIMP( currentTarget, c[final].putSelector, value, c[final].additionalArg );
}

-(void)bindToTarget:aTarget
{
    [self _setTarget:aTarget];
    id currentTarget=aTarget;
    for ( int i=0;i<count;i++) {
        [self bindComponent:components+i toTarget:currentTarget];
        currentTarget=getValueForComponents(currentTarget, components+i, 1);
    }
}

-valueForTarget:aTarget
{
    return getValueForComponents( aTarget, components, count);
}

-(void)setValue:newValue forTarget:aTarget
{
     setValueForComponents( aTarget, components, count,newValue);

}


-value {  return getValueForComponents( target, components, count); }

-(void)setValue:newValue
{
    setValueForComponents( target, components, count,newValue);
}


@end

#import "DebugMacros.h"
#import "MPWByteStream.h"
#import "MPWRusage.h"

@implementation MPWValueAccessor(testing)

+_testTarget
{
    return [MPWStream streamWithTarget:[MPWByteStream Stderr]];
}


+_testCompoundTarget
{
    return [MPWStream streamWithTarget:[MPWStream streamWithTarget:[MPWByteStream Stderr]]];
}

+(void)testBasicUnboundAccess
{
    MPWStream *t=[self _testTarget];
    MPWValueAccessor *accessor=[self valueForName:@"target"];
    IDEXPECT([accessor valueForTarget:t], [MPWByteStream Stderr], @"target");
}

+(void)testBasicUnboundSetAccess
{
    MPWStream *t=[self _testTarget];
    MPWValueAccessor *accessor=[self valueForName:@"target"];
    [accessor setValue:[MPWByteStream Stdout] forTarget:t];
    IDEXPECT([t target], [MPWByteStream Stdout], @"target");
}


+(void)testBoundGetSetAccess
{
    MPWStream *t=[self _testTarget];
    MPWValueAccessor *accessor=[self valueForName:@"target"];
    [accessor bindToTarget:t];
    IDEXPECT([accessor value], [MPWByteStream Stderr], @"target after bind");
    [accessor setValue:[MPWByteStream Stdout]];
    IDEXPECT([t target], [MPWByteStream Stdout], @"newly set target after bind");
}

+(void)testPathAccess
{
    MPWStream *t=[self _testCompoundTarget];
    MPWValueAccessor *accessor=[[[self alloc] initWithPath:@"target/target"] autorelease];
    [accessor bindToTarget:t];
    IDEXPECT([accessor value], [MPWByteStream Stderr], @"target after bind");
    [accessor setValue:[MPWByteStream Stdout]];
    IDEXPECT([[t target] target], [MPWByteStream Stdout], @"newly set target after bind");
}

#define ACCESS_COUNT  1000000

+(void)testPerformanceOfPathAccess
{
    NSString *keyPath=@"target/target";
    MPWStream *t=[self _testCompoundTarget];
    MPWValueAccessor *accessor=[[[self alloc] initWithPath:keyPath] autorelease];
    MPWRusage* accessorStart=[MPWRusage current];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [accessor valueForTarget:t];
    }
    MPWRusage* accessorTime=[MPWRusage timeRelativeTo:accessorStart];
    MPWRusage* boundAccessorStart=[MPWRusage current];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [accessor valueForTarget:t];
    }
    [accessor bindToTarget:t];
    MPWRusage* boundAccessorTime=[MPWRusage timeRelativeTo:boundAccessorStart];
    MPWRusage* kvcStart=[MPWRusage current];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [t valueForKeyPath:@"target.target"];
    }
    MPWRusage* kvcTime=[MPWRusage timeRelativeTo:kvcStart];
    double unboundRatio = (double)[kvcTime userMicroseconds] / (double)[accessorTime userMicroseconds];
#define EXPECTEDUNBOUNDRATIO 12.0
    NSAssert2( unboundRatio > EXPECTEDUNBOUNDRATIO ,@"ratio of value accessor to kvc path %g < %g",
              unboundRatio,EXPECTEDUNBOUNDRATIO);
    
    double boundRatio = (double)[kvcTime userMicroseconds] / (double)[boundAccessorTime userMicroseconds];
#define EXPECTEDBOUNDRATIO 12.0
    NSAssert2( boundRatio > EXPECTEDBOUNDRATIO ,@"ratio of bound value accessor to kvc path %g < %g",
              boundRatio,EXPECTEDBOUNDRATIO);
    

    
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicUnboundAccess",
            @"testBasicUnboundSetAccess",
            @"testBoundGetSetAccess",
            @"testPathAccess",
            @"testPerformanceOfPathAccess",
            nil];
}

@end
