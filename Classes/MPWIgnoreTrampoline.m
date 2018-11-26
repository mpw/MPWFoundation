/*
	MPWIgnoreTrampoline.m created by marcel on Wed 01-Sep-1999
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

R

*/


#import "MPWIgnoreTrampoline.h"
#import "MPWObjectCache.h"
#import <objc/runtime.h>

@implementation MPWIgnoreTrampoline

//CACHING_ALLOC( quickTrampoline, 5, YES )

//#define CACHING_ALLOC( selector, size, unsafe  )
static pthread_key_t key=0;
static void __objc_cache_destructor( void *objref )  { [(id)objref release]; }
+quickTrampoline  {
//    NSLog(@"quickTrampoline");
	if ( !key ) {
		pthread_key_create(&key, __objc_cache_destructor);
	}
	MPWObjectCache *cache=pthread_getspecific( key  );
	if ( !cache ) {
		cache = [[MPWObjectCache alloc] initWithCapacity:5 class:self];
		[cache setUnsafeFastAlloc:YES];
		pthread_setspecific( key, cache );
	}
//    NSLog(@"quickTrampoline initialized about to GETOBJECT");

	return GETOBJECT(cache);
}

static id  __ignore( MPWIgnoreTrampoline* target, SEL selector )
{
    return [target xxxTarget];
}


+(BOOL)resolveInstanceMethod:(SEL)selector
{
//    NSLog(@"methodSignatureForSelector");
    class_addMethod(self, selector, (IMP)__ignore, "@@:");
    return YES;
}



-methodSignatureForSelector:(SEL)aSelector
{
    NSLog(@"methodSignatureForSelector");
    id sig = [NSObject methodSignatureForSelector:@selector(class)];
    return sig;
}

-(void)xxxSetTargetKey:aKey
{
	//--- just ignore
}

+(BOOL)respondsToSelector:(SEL)aSelector
{
    return YES;
}

-(BOOL)respondsToSelector:(SEL)aSelector
{
    return YES;
}

-(void)forwardInvocation:(NSInvocation*)invocationToForward
{
    NSLog(@"empty ignore trampoline forwardInvocation");
//    NSLog(@"empty ignore trampoline forwardInvocation: %@",invocationToForward);
    [invocationToForward setReturnValue:&xxxTarget];
}

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"testAutorelease",nil
    ];
}



@end
