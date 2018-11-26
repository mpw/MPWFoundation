/* NSInvocationAdditions_lookup.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
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
#import <objc/message.h>

// extern IMP class_lookupMethod( Class aClass , SEL msg );		for 10.4 or earlier
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 ) || TARGET_OS_IPHONE

//extern id objc_msgSend(id receiver, SEL _cmd, ...);
static inline IMP objc_class_msg_lookup( Class aClass, SEL msg )
{
//	return objc_msgSend;
//	return [aClass  instanceMethodForSelector:msg];

    return class_getMethodImplementation( aClass, msg );
}

// #warning define objc_msg_lookup in terms of class_getMethodImplementation
//extern id objc_msgSend( id, SEL, ... );
static inline IMP objc_msg_lookup( id obj, SEL msg )
{
//	return objc_msgSend;
//	return [obj methodForSelector:msg];

//    if ( obj ) {
//       return class_getMethodImplementation(*(Class*)obj, msg );
//    } else {
    return objc_msgSend;
//    }
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


