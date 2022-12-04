/*
	DeubgMacros.h 

    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

*/

#ifndef DEBUGMACROS
#define DEBUGMACROS



#import <Foundation/Foundation.h>
//#import <Foundation/NSDebug.h>

//extern int debug;

static inline BOOL _idsAreEqual( id a, id b ) {
    return a==b || [a isEqual:b];
}
#define ROUNDTOINTFORTEST( aValue )   ((int)round(aValue))

//#if !defined(MPWTESTASSERT)
//#define MPWTESTASSERT(condition, desc, ...)    \
//do {                \
//__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
//if (!(condition)) {        \
//[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
//object:self file:[NSString stringWithUTF8String:__FILE__] \
//lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
//}                \
//__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
//} while(0)
//#endif


#if !defined(MPWTESTASSERT)
#define MPWTESTASSERT(condition, desc, ...)    \
do {                \
if (!(condition)) {        \
[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
object:self file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
}                \
} while(0)
#endif


#define EXPECTTRUE( got , msg ) \
MPWTESTASSERT( (got) , ([NSString stringWithFormat:@"%@ was false instead of expected true",msg]),@"");
#define EXPECTFALSE( got , msg ) \
MPWTESTASSERT( !(got) , ([NSString stringWithFormat:@"%@ was true instead of expected false",msg]),@"");
#define EXPECTNOTNIL( got , msg ) \
MPWTESTASSERT( (got)!=NULL, ([NSString stringWithFormat:@"%@ was nil but expected non-nil",msg]),@"");
#define EXPECTNIL( got , msg ) \
MPWTESTASSERT( (got) == nil , ([NSString stringWithFormat:@"%@ was %p instead of nil",msg,got]),@"");
#define INTEXPECT( got, expect, msg  ) \
MPWTESTASSERT(((long)expect)==((long)got) , ([NSString stringWithFormat:@"got %ld instead of expected %ld for %@",(long)got,(long)expect,msg]),@"");
#define HEXEXPECT( got, expect, msg  ) \
MPWTESTASSERT(((long)expect)==((long)got) , ([NSString stringWithFormat:@"got 0x%lx instead of expected 0x%lx for %@",(long)got,(long)expect,msg]),@"");
#define RECTEXPECT( rect, ex,ey,ew,eh , msg) \
{ \
int _ax=ROUNDTOINTFORTEST(rect.origin.x);\
int _ay=ROUNDTOINTFORTEST(rect.origin.y);\
int _aw=ROUNDTOINTFORTEST(rect.size.width);\
int _ah=ROUNDTOINTFORTEST(rect.size.height);\
MPWTESTASSERT( _ax==ex &&  _ay==ey && \
_aw==ew && _ah==eh , \
([NSString stringWithFormat:@"%@ instead of expected %@ for %@", \
NSStringFromRect(NSMakeRect(_ax, _ay, _aw, _ah)),\
NSStringFromRect(NSMakeRect(ex, ey, ew, eh)),msg]),@""); \
}
#define FLOATEXPECT( got, expect, msg  ) \
MPWTESTASSERT((expect)==(got) , ([NSString stringWithFormat:@"%g instead of expected %g for %@",(double)got,(double)expect,msg]),@"");

#define FLOATEXPECTTOLERANCE( got, expect, tol, msg  ) \
MPWTESTASSERT(fabs((expect)-(got)) < (tol) ,  ([NSString stringWithFormat:@"got %g instead of expected %g for %@",(double)got,(double)expect,msg]),@"");

#define _IDEXPECT(  got,  expected,  msg,  self,  _cmd ) { \
id _expected=expected;\
id _got = got; \
MPWTESTASSERT( _idsAreEqual(_expected,_got),  ([NSString stringWithFormat:@"got '%@' instead of expected '%@' for %@",_got,_expected,msg]),@""); \
} 

#define IDEXPECT( got , expected, msg )  _IDEXPECT( got, expected, msg, self, _cmd )


#ifndef NeXT
/*
#define	D0PRINTF( msg,arg...)	\
	NSLog( @"%s:%d(%s): %c%s -> "#msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] UTF8String], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) UTF8String],arg )
*/
#endif
#define D0PRINTF3( msg, arg1, arg2,arg3 ) \
	NSLog( @"%s:%d(%s): %c%s -> "#msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] UTF8String], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) UTF8String],arg1,arg2,arg3 )
#define	D0PRINTF2( msg, arg1,arg2 )	\
	NSLog( @"%s:%d(%s): %c%s -> "#msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] UTF8String], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) UTF8String],arg1,arg2 )
#define D0PRINTF1( msg, arg1 ) \
	NSLog( @"%s:%d(%s): %c%s -> "#msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] UTF8String], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) UTF8String],arg1 )
#define	D0PRINTF0( msg )	\
	NSLog( @"%s:%d(%s): %c%s -> "#msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] UTF8String], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) UTF8String])



#define DEBUG1 ([NSObject debugLevel])
#define DEBUG2 ([NSObject debugLevel] >= 2)
#define DEBUG3 ([NSObject debugLevel] >= 3)
#define DEBUG4 ([NSObject debugLevel] >= 4)
#define DEBUG5 ([NSObject debugLevel] >= 5)
#define DEBUG6 ([NSObject debugLevel] >= 6)
#define DEBUG7 ([NSObject debugLevel] >= 7)
#define DEBUG8 ([NSObject debugLevel] >= 8)
#define DEBUG9 ([NSObject debugLevel] >= 9)
#define DEBUG10 ([NSObject debugLevel] >= 10)
#define DEBUG11 ([NSObject debugLevel] >= 11)
#define DEBUG12 ([NSObject debugLevel] >= 12)

#define D1PRINTF0 if (DEBUG1) D0PRINTF0
#define D1PRINTF1 if (DEBUG1) D0PRINTF1
#define D1PRINTF2 if (DEBUG1) D0PRINTF2
#define D1PRINTF3 if (DEBUG1) D0PRINTF3

#define D2PRINTF0 if (DEBUG2) D0PRINTF0
#define D2PRINTF1 if (DEBUG2) D0PRINTF1
#define D2PRINTF2 if (DEBUG2) D0PRINTF2
#define D2PRINTF3 if (DEBUG2) D0PRINTF3

#define D3PRINTF0 if (DEBUG3) D0PRINTF0
#define D3PRINTF1 if (DEBUG3) D0PRINTF1
#define D3PRINTF2 if (DEBUG3) D0PRINTF2
#define D3PRINTF3 if (DEBUG3) D0PRINTF3

#define D4PRINTF0 if (DEBUG4) D0PRINTF0
#define D4PRINTF1 if (DEBUG4) D0PRINTF1
#define D4PRINTF2 if (DEBUG4) D0PRINTF2
#define D4PRINTF3 if (DEBUG4) D0PRINTF3

#define D5PRINTF0 if (DEBUG5) D0PRINTF0
#define D5PRINTF1 if (DEBUG5) D0PRINTF1
#define D5PRINTF2 if (DEBUG5) D0PRINTF2
#define D5PRINTF3 if (DEBUG5) D0PRINTF3

#define D6PRINTF0 if (DEBUG6) D0PRINTF0
#define D6PRINTF1 if (DEBUG6) D0PRINTF1
#define D6PRINTF2 if (DEBUG6) D0PRINTF2
#define D6PRINTF3 if (DEBUG6) D0PRINTF3

#define D7PRINTF0 if (DEBUG7) D0PRINTF0
#define D7PRINTF1 if (DEBUG7) D0PRINTF1
#define D7PRINTF2 if (DEBUG7) D0PRINTF2
#define D7PRINTF3 if (DEBUG7) D0PRINTF3

#define D8PRINTF0 if (DEBUG8) D0PRINTF0
#define D8PRINTF1 if (DEBUG8) D0PRINTF1
#define D8PRINTF2 if (DEBUG8) D0PRINTF2
#define D8PRINTF3 if (DEBUG8) D0PRINTF3

#define D9PRINTF0 if (DEBUG9) D0PRINTF0
#define D9PRINTF1 if (DEBUG9) D0PRINTF1
#define D9PRINTF2 if (DEBUG9) D0PRINTF2
#define D9PRINTF3 if (DEBUG9) D0PRINTF3

#define D10PRINTF0 if (DEBUG10) D0PRINTF0
#define D10PRINTF1 if (DEBUG10) D0PRINTF1
#define D10PRINTF2 if (DEBUG10) D0PRINTF2
#define D10PRINTF3 if (DEBUG10) D0PRINTF3

#define D11PRINTF0 if (DEBUG11) D0PRINTF0
#define D11PRINTF1 if (DEBUG11) D0PRINTF1
#define D11PRINTF2 if (DEBUG11) D0PRINTF2
#define D11PRINTF3 if (DEBUG11) D0PRINTF3

#define D12PRINTF0 if (DEBUG12) D0PRINTF0
#define D12PRINTF1 if (DEBUG12) D0PRINTF1
#define D12PRINTF2 if (DEBUG12) D0PRINTF2
#define D12PRINTF3 if (DEBUG12) D0PRINTF3

#define	ENTER1	D1PRINTF0(@"enter");
#define	ENTER2	D2PRINTF0(@"enter");
#define	ENTER3	D3PRINTF0(@"enter");
#define	ENTER4	D4PRINTF0(@"enter");
#define	ENTER5	D5PRINTF0(@"enter");
#define	ENTER6	D6PRINTF0(@"enter");
#define	ENTER12	D12PRINTF0(@"enter");

#define	LEAVE1	D1PRINTF0(@"leave");
#define	LEAVE2	D2PRINTF0(@"leave");
#define	LEAVE3	D3PRINTF0(@"leave");
#define	LEAVE4	D4PRINTF0(@"leave");
#define	LEAVE5	D5PRINTF0(@"leave");
#define	LEAVE6	D6PRINTF0(@"leave");
#define	LEAVE12	D12PRINTF0(@"leave");

#define MPWConvertVarToString( x ) ({  typeof(x) _Y_=x; \
MPWConvertToString(&_Y_,@encode(typeof(_Y_))); })

#define LOG(x)  NSLog(@"%s: '%@'",#x,MPWConvertVarToString(x))

#endif
