/* MPWEnumSelectFilter.m Copyright (c) 1998-1999 by Marcel Weiher, All Rights Reserved.


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


#import "MPWEnumSelectFilter.h"
#import "MPWFakedReturnMethodSignature.h"
#import "MPWObjectCache.h"

@implementation MPWEnumSelectFilter

CACHING_ALLOC( quickFilter, 30, NO )

- (NSMethodSignature *)methodSignatureForHOMSelector:(SEL)aSelector
{
//	NSLog(@"will return faked method signature");
	return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
}


- (NSMethodSignature *)methodSignatureForHOMSelector1:(SEL)aSelector
{
    //--- Return an arbitray message if there is no arguments[1]
    //--- (there were no objects to filter).  Otherwise, we would
    //--- get a runtime error (message not understood) instead of
    //--- an empty return list
    id sig;
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"getting sig for %@",NSStringFromSelector(aSelector));
    }
#endif
//	NSLog(@"arguments[1]=%x",arguments[1]);
//	NSLog(@"arguments[1]=%@",arguments[1]);
    if ( arguments[1] ) {
        sig = [arguments[1] methodSignatureForSelector:aSelector];
//		NSLog(@"sig=%x",sig);
        if ( sig == nil ) {
            //--- retry, forcing methods in categories to be
            //--- loaded ( they aren't by methodSignatureForSelector: )
            [arguments[1] methodForSelector:aSelector];
            sig = [arguments[1] methodSignatureForSelector:aSelector];
            if ( sig == nil ) {
                sig = [arguments[1] methodSignatureForSelector:[self mapSelector:aSelector]];
            }
        }
        if ( sig ) {
			id fakeSig;
//			NSLog(@"return faked method signature");
			fakeSig = [MPWFakedReturnMethodSignature fakeSignatureWithSignature:sig];
			if (fakeSig ) {
				sig=fakeSig;
			} else {
				[NSException raise:@"illegalstate" format:@"Couldn't create fake method signature for %@",NSStringFromSelector(aSelector)];
			}
        } else {
            NSLog(@"couldn't find sig for selector %@ original object %@",NSStringFromSelector(aSelector),arguments[1]);
        }
    } else {
        sig = [NSObject methodSignatureForSelector:@selector(class)];
    }
/*
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"sig for %@ = %@/%@ %d",NSStringFromSelector(aSelector),sig,[sig class],[sig methodReturnType]);
    }
#endif
*/
//	NSLog(@"returning sig=%x",sig);
    return sig;
}

+testSelectors
{
	return [NSArray arrayWithObjects:		// nothing for now
		nil];
}


@end
