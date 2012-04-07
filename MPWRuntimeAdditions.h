/* MPWRuntimeAdditions.h Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


@interface NSMethodSignature(types)
#if Darwin
#if 0
-(const char*)types;
#endif
#endif
@end

@interface NSObject(methodAliasing)
+(void)addMethod:(IMP)method forSelector:(SEL)selector types:(const char*)types;
+(void)aliasInstanceMethod:(SEL)old to:(SEL)newSel in:(Class)newClass;
+(void)aliasMethod:(SEL)old to:(SEL)newSel in:(Class)newClass;
+(void)aliasInstanceMethod:(SEL)old to:(SEL)newSel;
@end

@interface NSObject(defaultedVoidMethod)

-(IMP)defaultedVoidMethodForSelector:(SEL)sel;
-(IMP)boolMethodForSelector:(SEL)sel defaultValue:(BOOL)defaultValue;

@end


@interface NSObject(instanceSize)

+(int)instanceSize;

@end
