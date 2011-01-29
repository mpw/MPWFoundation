/* NSInvocationAdditions_lookup.h Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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

// #warning  NSInvocationAdditions_lookup

#if Darwin  || TARGET_OS_IPHONE
//#import "NSInvocationAdditions.h"

#if TARGET_OS_IPHONE
#import <objc/runtime.h>
#else
#import <objc/objc-runtime.h>
#endif
//#define FAST_MSG_LOOKUPS  1


// extern IMP class_lookupMethod( Class aClass , SEL msg );		for 10.4 or earlier
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 ) || TARGET_OS_IPHONE

extern id objc_msgSend(id receiver, SEL _cmd, ...);
static inline IMP objc_class_msg_lookup( Class aClass, SEL msg )
{
//	return objc_msgSend;
//	return [aClass  instanceMethodForSelector:msg];

    return class_getMethodImplementation( aClass, msg );
}

// #warning define objc_msg_lookup in terms of class_getMethodImplementation
extern id objc_msgSend( id, SEL, ... );
static inline IMP objc_msg_lookup( id obj, SEL msg )
{
//	return objc_msgSend;
//	return [obj methodForSelector:msg];

    if ( obj ) {
       return class_getMethodImplementation(*(Class*)obj, msg );
    } else {
        return objc_msgSend;
    }
}
#else

#error no objc_msg_lookup

#endif

#define CACHED_LOOKUP_WITH_CACHE( obj, msg,lastImp , lastClass ) \
{\
   extern id _objc_msgForward(id sef, SEL _cmd, ...);\
   if ( obj && *(Class*)obj != lastClass  ) \
   {\
       lastClass=*(Class*)obj;\
       lastImp=(IMP)objc_msg_lookup( obj, msg );\
   }\
   if ( lastImp == (IMP)NULL || lastImp == (IMP)_objc_msgForward ) {\
       lastImp=(IMP)objc_msgSend;\
   }\
} 

#define CACHED_LOOKUP( obj, msg ) \
{\
    static Class lastClass=(Class)nil;\
    static IMP lastImp=(IMP)nil;\
    CACHED_LOOKUP_WITH_CACHE( obj, msg,lastImp , lastClass) \
}



#else


#endif


