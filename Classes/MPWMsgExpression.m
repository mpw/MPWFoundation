/*
	MPWMsgExpression.m   -  reified expressions
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

    Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the distribution.

    Neither the name Marcel Weiher nor the names of contributors may
    be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/

#if 0
#import "MPWMsgExpression.h"
#import "MPWTrampoline.h"
#import "NSInvocationAdditions.h"
#import <objc/objc-runtime.h>

#undef Darwin

@interface NSObject(expressions)

-xxxEval;
-quote;
-receiverExpr:sourceExpr;
-(IMP)evalFunc;

@end
@interface NSInvocation(expressions)

+(NSInvocation*)invocationWithInvocation:(NSInvocation*)other;
-prebind;

@end


@implementation MPWMsgExpression

#ifdef Darwin

-prebind
{
    id sig = [self methodSignature];
    int i;
    argumentCount = [sig numberOfArguments]-2;
    receiver = [self target];
    selector = [self selector];
    cachedImp=objc_msgSend;
    for (i=0;i<argumentCount;i++) {
        argTypes[i]=*[sig getArgumentTypeAtIndex:i+2];
        if ( argTypes[i]=='@' || argTypes[i]=='i' || argTypes[i]=='I' || argTypes[i]=='f' || argTypes[i]=='s') {
            [self getArgument:&boundArgs[i] atIndex:i+2];
        } else {
            //---	cannot bind
            return self;
        }        
    }
    eval = [self methodForSelector:@selector(xxxDoEval)];
    prebound=YES;
    return self;
}

+(NSInvocation*)invocationWithInvocation:(NSInvocation*)other
{
    return [[super invocationWithInvocation:other] prebind];
}

-eval
{
    return [self xxxEval];
}

-(void)invokeWithTarget:newTarget
{
    id result;
    if ( prebound ) {
        result=objc_msgSend( newTarget, selector, boundArgs[0],boundArgs[1],boundArgs[2],boundArgs[3]);
        [self setReturnValue:&result];
    } else {
        [super invokeWithTarget:newTarget];
    }
}

-xxxEval:environment
{
    id result;
    if ( prebound ) {
        int i;
        id	newReceiver;
        id args[8];
        for (i=0;i<argumentCount;i++) {
            if ( argTypes[i]=='@' ) {
                args[i]=[boundArgs[i] xxxEval:environment];
            } else {
                args[i]=boundArgs[i];
            }
        }
        newReceiver = evalFun( receiver, @selector(xxxEval:),environment);
        if ( *(Class*)newReceiver != cachedClass ) {
            cachedImp = [newReceiver methodForSelector:selector];
            cachedClass = *(Class*)newReceiver;
        }
        result=cachedImp( newReceiver, selector, args[0],args[1],args[2],args[3] );
//        [self setReturnValue:&result];
    } else {
        result= [super xxxEval:environment];
    }
    return result;
}

-(void)setTarget:newTarget
{
    [super setTarget:newTarget];
    receiver=newTarget;
    if ( *(Class*)receiver != cachedEvalClass ) {
        evalFun = [receiver evalFunc];
        cachedEvalClass = *(Class*)receiver;
    }
}

/*
-(void)setReceiver:newReceiver
{
    if ( newReceiver != receiver ) {
        receiver = newReceiver;
        if ( *(Class*)receiver != cachedClass ) {
            evalFunc=[receiver evalFunc];
        }
    }
}
*/

-(void)invoke
{
    [self invokeWithTarget:[self target]];
}

#endif

@end

@implementation NSInvocation(expressions)

+(NSInvocation*)invocationWithInvocation:(NSInvocation*)other
{
    id copy=[self invocationWithMethodSignature:[other methodSignature]];
    int i,argumentCount;
    void *buffer=alloca( 128 );
    for (i=0,argumentCount=[[other methodSignature] numberOfArguments];i<argumentCount;i++) {
        [other getArgument:buffer atIndex:i];
        [copy setArgument:buffer atIndex:i];
    }
    if ( [other argumentsRetained] ) {
        [copy retainArguments];
    }
    return copy;
}

-prebind
{
    return self;
}

-receiverExpr:sourceExpr
{
    return [[self target] receiverExpr:self];
}

-receiverExpr
{
    return [self receiverExpr:self];
}

-(void)setReceiver:receiver
{
    [[self receiverExpr] setTarget:receiver];
}

-copyWithZone:(NSZone*)zone
{
    return [[isa invocationWithInvocation:self] retain];
}

-xxxAsExpression
{
    return nil;
}

-xxxDoEval:environment
{
    int i,argumentCount;
    id sig,result;

    sig = [self methodSignature];
    argumentCount = [sig numberOfArguments];
    for (i=2;i<argumentCount;i++) {
        if ( *[sig getArgumentTypeAtIndex:i]=='@' ) {
            id argument;
            [self getArgument:&argument atIndex:i];
            argument = [argument xxxEval:environment];
            [self setArgument:&argument atIndex:i];
        }
    }
    [self invokeWithTarget:[[self target] xxxEval:environment]];
    [self getReturnValue:&result];
    return result;
}

-xxxEval:environment
{
    return [[self copy] xxxDoEval:environment];
}


@end

@implementation MPWMsgExpression(msgExpressionTesting)


+testSelectors
{
    return [NSArray arrayWithObjects:
        @"testSimpleExpression",@"testSimpleExpressionTwice",@"testAsExpr",@"testAsComplexExpr",nil];
}

+(void)testSimpleExpression
{
    id testString = @"hi";
    id testArg = @" there";
    id invocation = [self invocationWithTarget:testString andSelector:@selector(stringByAppendingString:)];
    id result,testresult = [testString stringByAppendingString:testArg];
    [invocation setTarget:testString];
    [invocation setArgument:&testArg atIndex:2];
//    NSLog(@"invocation %@",invocation);
    result = [invocation xxxEval];
    NSAssert2( [result isEqual:testresult],@"expression result '%@' different from direct execution result '%@'",result,testresult);

}

+(void)testSimpleExpressionTwice
{
    id testString = @"hi";
    id testArg = @" there";
    id invocation = [self invocationWithTarget:testString andSelector:@selector(stringByAppendingString:)];
    id result1,result2,testresult = [testString stringByAppendingString:testArg];
    [invocation setTarget:testString];
    [invocation setArgument:&testArg atIndex:2];
//    NSLog(@"invocation %@",invocation);
    result1 = [invocation xxxEval];
    result2 = [invocation xxxEval];
    NSAssert2( [result1 isEqual:testresult],@"first expression result '%@' different from direct execution result '%@'",result1,testresult);
    NSAssert2( [result2 isEqual:testresult],@"second expression result '%@' different from direct execution result '%@'",result2,testresult);

}

+(void)testAsExpr
{
    id testString = @"hi";
    id testArg = @" there";
    id result,testresult = [testString stringByAppendingString:testArg];
    id expr = [[testString quote] stringByAppendingString:testArg];
    result = [expr xxxEval];
    NSAssert2( [result isEqual:testresult],@"testAsExpr result '%@' different from direct execution result '%@'",result,testresult);
}

+(void)testAsComplexExpr
{
    id testString = @"hi";
    id testArg = @" there";
    id result1,result2,testresult = [testString stringByAppendingString:[testString stringByAppendingString:testArg]];
    id expr = [[testString quote] stringByAppendingString:[[testString quote] stringByAppendingString:testArg]];
    result1 = [expr xxxEval];
    result2 = [expr xxxEval];
    NSAssert2( [result1 isEqual:testresult],@"first expression result '%@' different from direct execution result '%@'",result1,testresult);
    NSAssert2( [result2 isEqual:testresult],@"second expression result '%@' different from direct execution result '%@'",result2,testresult);
}

@end

@implementation NSObject(expressions)

-(IMP)evalFunc
{
    return [self methodForSelector:@selector(xxxEval:)];
}


-receiverExpr:sourceExpr
{
    return sourceExpr;
}

-xxxAsExpression
{
    return self;
}

-xxxEval:environment
{
    return self;
}

-xxxEval
{
    return [self xxxEval:nil];
}

-asTargetOfExpression:(NSInvocation*)invocation
{
    id expression = [MPWMsgExpression invocationWithInvocation:invocation];
    [expression setTarget:self];
#ifdef Darwin
    [invocation setReturnType:NSObjCObjectType];
#endif
    [invocation setReturnValue:&expression];
    return expression;
}

-quote
{
    id trampoline = [MPWTrampoline trampoline];

    [trampoline setXxxTarget:self];
    [trampoline setXxxSelector:@selector(asTargetOfExpression:)];
    return trampoline;
}
@end
#endif 
