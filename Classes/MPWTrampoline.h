/*

    MPWTrampoline.h created by marcel on Tue 29-Jun-1999
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

R

*/


#import <Foundation/Foundation.h>
#import <Foundation/NSProxy.h>
#import <MPWFoundation/AccessorMacros.h>

@interface MPWTrampoline : NSProxy
{
    int	retainCount;
	id	xxxTarget;
	SEL xxxSelector;
	id  xxxAdditionalArg;
}

idAccessor_h( xxxTarget, setXxxTarget )
scalarAccessor_h( SEL, xxxSelector, setXxxSelector )
idAccessor_h( xxxAdditionalArg, setXxxAdditionalArg )

+trampolineWithTarget:target selector:(SEL)selector;
+trampoline;
+quickTrampoline;
-sendTarget;
-(void)xxxSetTargetKey:aKey;
+(IMP)instanceMethodForSelector:(SEL)sel;
@end


@interface NSObject(safely)

-(NSMethodSignature*)methodSignatureForHOMSelector:(SEL)aSelector;

#if ! TARGET_OS_IPHONE
-exceptionPerformingInvocation:(NSInvocation*)invocation;
-safely;
#endif

@end


