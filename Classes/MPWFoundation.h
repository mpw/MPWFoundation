/* MPWFoundation.h Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/CodingAdditions.h>
#import <MPWFoundation/DebugMacros.h>
#import <MPWFoundation/MPWObject.h>
#import <MPWFoundation/NSInvocationAdditions.h>
#import <MPWFoundation/MPWRuntimeAdditions.h>
#import <MPWFoundation/MPWMsgExpression.h>
#import <MPWFoundation/NSStringAdditions.h>
#import <MPWFoundation/NSObjectAdditions.h>
#import <MPWFoundation/MPWAssociation.h>

#import <MPWFoundation/MPWStream.h>
#import <MPWFoundation/MPWFlattenStream.h>
#import <MPWFoundation/MPWByteStream.h>
#import <MPWFoundation/MPWHierarchicalStream.h>

#import <MPWFoundation/MPWTrampoline.h>
#import <MPWFoundation/MPWIgnoreTrampoline.h>
//#import <MPWFoundation/MPWEnumFilter.h>
#import <MPWFoundation/NSObjectFiltering.h>
#import <MPWFoundation/MPWEnumeratorEnumerator.h>
#import <MPWFoundation/MPWRealArray.h>
#import <MPWFoundation/MPWUniqueString.h>
#import <MPWFoundation/MPWUShortArray.h>
#if !__has_feature(objc_arc)
#import <MPWFoundation/MPWObjectCache.h>
#endif
#import <MPWFoundation/MPWSubData.h>
#import <MPWFoundation/MPWScanner.h>
#import <MPWFoundation/MPWPoint.h>
#import <MPWFoundation/MPWRect.h>
#import <MPWFoundation/NSDictAdditions.h>
#import <MPWFoundation/MPWIdentityDictionary.h>
#import <MPWFoundation/MPWObjectReference.h>

#import <MPWFoundation/NSThreadInterThreadMessaging.h>
#import <MPWFoundation/bytecoding.h>
#import <MPWFoundation/NSRectAdditions.h>
#import <MPWFoundation/NSBundleConveniences.h>
#import <MPWFoundation/MPWIntArray.h>

#import <MPWFoundation/MPWNamedData.h>


#ifndef MIN
#define MIN(a,b)  ((a)<(b) ? (a):(b))
#endif
#ifndef MAX
#define MAX(a,b)  ((a)>(b) ? (a):(b))
#endif

