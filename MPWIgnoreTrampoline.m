/*
	MPWIgnoreTrampoline.m created by marcel on Wed 01-Sep-1999
    Copyright (c) 1999-2011 by Marcel Weiher. All rights reserved.

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


#import "MPWIgnoreTrampoline.h"
#import "MPWObjectCache.h"

@implementation MPWIgnoreTrampoline

//CACHING_ALLOC( quickTrampoline, 5, YES )

//#define CACHING_ALLOC( selector, size, unsafe  )
static pthread_key_t key=NULL;
static void __objc_cache_destructor( void *objref )  { [(id)objref release]; }
+quickTrampoline  {
	if ( !key ) {
		pthread_key_create(&key, __objc_cache_destructor);
	}
	MPWObjectCache *cache=pthread_getspecific( key  );
	if ( !cache ) {
		cache = [[MPWObjectCache alloc] initWithCapacity:5 class:self];
		[cache setUnsafeFastAlloc:YES];
		pthread_setspecific( key, cache );
	}
	return GETOBJECT(cache);
}



-methodSignatureForSelector:(SEL)aSelector
{
    return [NSObject methodSignatureForSelector:@selector(class)];
}

-(void)xxxSetTargetKey:aKey
{
	//--- just ignore
}

+(BOOL)respondsToSelector:(SEL)aSelector
{
    return YES;
}

-(void)forwardInvocation:(NSInvocation*)invocationToForward
{
    [invocationToForward setReturnValue:&xxxTarget];
}

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"testAutorelease",nil
    ];
}



@end
