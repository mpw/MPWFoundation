//
//  MPWIgnoreUnknownTrampoline.m
//  MPWFoundation
//
/*
    Copyright (c) 2005-2017 by Marcel Weiher. All rights reserved.

R

*/

//

#import "MPWIgnoreUnknownTrampoline.h"
#import "NSInvocationAdditions.h"
#import "MPWObjectCache.h"
#import <objc/runtime.h>

@implementation MPWIgnoreUnknownTrampoline

CACHING_ALLOC( quickTrampoline, 5, YES )


-(void)doesNotRecognizeSelector:(SEL)selector
{
	NSLog(@"MPWIgnoreUnknownTrampoline -doesNotRecognizeSelector");
}

+(void)doesNotRecognizeSelector:(SEL)selector
{
	NSLog(@"MPWIgnoreUnknownTrampoline +doesNotRecognizeSelector");
}

+(BOOL)respondsToSelector:(SEL)aSelector
{
//	NSLog(@"respondsToSelector");
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig;
//	NSLog(@"method signature for selector");
    sig = [[self sendTarget] methodSignatureForSelector:aSelector];
    if (!sig ) {
        sig = [NSObject methodSignatureForSelector:@selector(class)];
    }
    return sig;
}


@end

#define HOM_METHOD1( msg, type, conversion, trampileClass ) \
-msg:(type)arg  { id tramp = [trampileClass trampolineWithTarget:self selector:@selector(msg:withArg:)]; [tramp setXxxAdditionalArg:conversion]; return tramp; } \
-msg:(NSInvocation*)invocation withArg:arg

#define HOM_METHOD_DOUBLE( msg )    HOM_METHOD1( msg, double, [NSNumber numberWithDouble:arg] )



#define HOM_METHOD( msg , trampileClass ) \
-msg { return [trampileClass trampolineWithTarget:self selector:@selector(msg:)]; } \
-msg:(NSInvocation*)invocation
//   invocation=(NSInvocation*)[MPWStackSaverInvocation withInvocation:invocation];


@implementation NSObject(ifResponds)



HOM_METHOD(ifResponds, MPWIgnoreUnknownTrampoline)
{
    id retval=nil;
    if ( [self respondsToSelector:[invocation selector]]) {
        retval =[invocation returnValueAfterInvokingWithTarget:self];
    }
    return retval;
}


HOM_METHOD(sendSuperChain, MPWIgnoreUnknownTrampoline)
{
    IMP theIMP=NULL;
    Class oldClass=[self class];
    Class currentClass=oldClass;
    SEL selector=[invocation selector];
    @try {
        while ( currentClass) {
            if ( [currentClass instancesRespondToSelector:selector]) {
                IMP newIMP=[currentClass instanceMethodForSelector:selector];
                if ( newIMP != theIMP) {
                    theIMP=newIMP;
                    if ( theIMP  ) {
                        object_setClass( self, currentClass);
                        [invocation invokeWithTarget:self];
                    }
                }
                currentClass=[currentClass superclass];
            } else {
                break;
            }
        }
    }
    @finally {
        object_setClass( self, oldClass);
    }
    return nil;
}


@end

@interface MPWIgnoreUnknownTrampolineTesting : NSObject {} @end
@interface NSString(doesntReallyRespondToStringValue1)
-stringValue1;
@end

static int superChaintTesterCounter=0;
@interface SuperchainTester1 : NSObject
@end
@interface SuperchainTester2 : SuperchainTester1
@end
@interface SuperchainTester3 : SuperchainTester2
@end

@implementation SuperchainTester1

-(void)doit
{
    superChaintTesterCounter += 100;
}

@end


@implementation SuperchainTester2

@end


@implementation SuperchainTester3

-(void)doit
{
    superChaintTesterCounter += 1;
}

@end

@implementation MPWIgnoreUnknownTrampolineTesting

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testIfResponds",
            @"testSuperchainCaller",
            @"testIfRespondsWithVoidReturn",

            nil];
}


+(void)testIfResponds
{
    id a = @"John Doe";
    id  str = [a stringValue];
    IDEXPECT( str, a ,@"safely sending should yield same value if exists" );
    [[a ifResponds] stringValue1];
}

static int globalTester=0;
+(void)tester
{
    globalTester=42;
    return ;
}

+(void)testIfRespondsWithVoidReturn
{
    globalTester=0;
    [[self ifResponds] tester];
    INTEXPECT(globalTester,42,@"should have called the test method");
}

+(void)testSuperchainCaller
{
    SuperchainTester3 *tester=[[SuperchainTester3 new] autorelease];
    [[tester sendSuperChain] doit];
    INTEXPECT(superChaintTesterCounter,101, @"called both implemenations, none twice");
}



@end
