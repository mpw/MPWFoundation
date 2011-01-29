/*
	DeubgMacros.h 

    Copyright (c) 1997-2011 by Marcel Weiher. All rights reserved.

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

#ifndef DEBUGMACROS
#define DEBUGMACROS



#import <Foundation/Foundation.h>
//#import <Foundation/NSDebug.h>

//extern int debug;

static inline BOOL _idsAreEqual( id a, id b ) {
    return a==b || [a isEqual:b];
}
#define ROUNDTOINTFORTEST( aValue )   ((int)round(aValue))
#define EXPECTTRUE( got , msg ) \
NSAssert1( (got) , ([NSString stringWithFormat:@"%@ was expected to be true",msg]),@"");
#define EXPECTFALSE( got , msg ) \
NSAssert1( !(got) , ([NSString stringWithFormat:@"%@ was expected to be false",msg]),@"");
#define EXPECTNOTNIL( got , msg ) \
NSAssert1( (got)!=NULL, ([NSString stringWithFormat:@"%@ was expected to be non-nil but was nil",msg]),@"");
#define EXPECTNIL( got , msg ) \
NSAssert1( (got) == nil , ([NSString stringWithFormat:@"%@ was expected to be nil but was %p instead",msg,got]),@"");
#define INTEXPECT( got, expect, msg  ) \
NSAssert1((expect)==(got) , ([NSString stringWithFormat:@"%@ got %d instead of expected %d",msg,got,expect]),@"");
#define RECTEXPECT( rect, ex,ey,ew,eh , msg) \
{ \
int _ax=ROUNDTOINTFORTEST(rect.origin.x);\
int _ay=ROUNDTOINTFORTEST(rect.origin.y);\
int _aw=ROUNDTOINTFORTEST(rect.size.width);\
int _ah=ROUNDTOINTFORTEST(rect.size.height);\
NSAssert1( _ax==ex &&  _ay==ey && \
_aw==ew && _ah==eh , \
([NSString stringWithFormat:@"%@ got %@ instead of expected %@",msg, \
NSStringFromRect(NSMakeRect(_ax, _ay, _aw, _ah)),\
NSStringFromRect(NSMakeRect(ex, ey, ew, eh))]),@""); \
}
#define FLOATEXPECT( got, expect, msg  ) \
NSAssert1((expect)==(got) , ([NSString stringWithFormat:@"%@ got %g instead of expected %g",msg,got,expect]),@"");

#define FLOATEXPECTTOLERANCE( got, expect, tol, msg  ) \
NSAssert1(fabs((expect)-(got)) < (tol) ,  ([NSString stringWithFormat:@"%@ got %g instead of expected %g",msg,got,expect]),@"");

#define _IDEXPECT(  got,  expected,  msg,  self,  _cmd ) { \
id _expected=expected;\
id _got = got; \
NSAssert1( _idsAreEqual(_expected,_got),  ([NSString stringWithFormat:@"%@ got '%@' instead of expected '%@'",msg,_got,_expected]),@""); \
} 

#define IDEXPECT( got , expected, msg )  _IDEXPECT( got, expected, msg, self, _cmd )


#ifndef NeXT
/*
#define	D0PRINTF( msg,arg...)	\
	NSLog( @"%s:%d(%s): %c%s -> "msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] cString], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) cString],arg )
*/
#endif
#define D0PRINTF3( msg, arg1, arg2,arg3 ) \
	NSLog( @"%s:%d(%s): %c%s -> "msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] cString], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) cString],arg1,arg2,arg3 )
#define	D0PRINTF2( msg, arg1,arg2 )	\
	NSLog( @"%s:%d(%s): %c%s -> "msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] cString], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) cString],arg1,arg2 )
#define D0PRINTF1( msg, arg1 ) \
	NSLog( @"%s:%d(%s): %c%s -> "msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] cString], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) cString],arg1 )
#define	D0PRINTF0( msg )	\
	NSLog( @"%s:%d(%s): %c%s -> "msg@"\n", \
			__FILE__,__LINE__, \
			[[[self class] description] cString], \
			((id)[self class] == self) ? '+' : '-', \
			[NSStringFromSelector(_cmd) cString],msg )


#define DEBUG1 (NSDebugEnabled)
#define DEBUG2 (NSDebugEnabled >= 2)
#define DEBUG3 (NSDebugEnabled >= 3)
#define DEBUG4 (NSDebugEnabled >= 4)
#define DEBUG5 (NSDebugEnabled >= 5)
#define DEBUG6 (NSDebugEnabled >= 6)
#define DEBUG7 (NSDebugEnabled >= 7)
#define DEBUG8 (NSDebugEnabled >= 8)
#define DEBUG9 (NSDebugEnabled >= 9)
#define DEBUG10 (NSDebugEnabled >= 10)
#define DEBUG11 (NSDebugEnabled >= 11)
#define DEBUG12 (NSDebugEnabled >= 12)

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
