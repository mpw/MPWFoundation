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

@implementation MPWValueAccessor

idAccessor(target, _setTarget)

extern id objc_msgSend(id, SEL, ...);

+valueForName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}

-initWithName:(NSString*)name
{
    self=[super init];
    if ( self ) {
        final.getSelector= NSSelectorFromString(name);
        final.putSelector=NSSelectorFromString([[@"set" stringByAppendingString:[name capitalizedString]] stringByAppendingString:@":"]);
        final.getIMP=objc_msgSend;
        final.putIMP=objc_msgSend;
        final.targetOffset=-1;
        
    }
    return self;
}

-(void)bindToTarget:aTarget
{
    [self _setTarget:aTarget];
//    final.targetClass=objc_getClass( aTarget);
    final.getIMP=[aTarget methodForSelector:final.getSelector];
    final.putIMP=[aTarget methodForSelector:final.putSelector];
    if ( (final.getIMP == NULL) || (final.putIMP == NULL) ) {
        [NSException raise:@"bind failed" format:@"bind failed"];
    }
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

-valueForTarget:aTarget
{
    return getValueForComponents( aTarget, &final, 1);
}

-(void)setValue:newValue forTarget:aTarget
{
     setValueForComponents( aTarget, &final, 1,newValue);

}


-value {  return getValueForComponents( target, &final, 1); }

-(void)setValue:newValue
{
    setValueForComponents( target, &final, 1,newValue);
}


@end

#import "DebugMacros.h"
#import "MPWByteStream.h"

@implementation MPWValueAccessor(testing)

+_testTarget
{
    return [MPWStream streamWithTarget:[MPWByteStream Stderr]];
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


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicUnboundAccess",
            @"testBasicUnboundSetAccess",
            @"testBoundGetSetAccess",
            nil];
}

@end
