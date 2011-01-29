/* MPWRuntimeAdditions.m Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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


#import "MPWRuntimeAdditions.h"
#import "MPWObject.h"
#import "DebugMacros.h"
//#import <objc/objc-class.h>
#if 1
#import <objc/runtime.h>
#else
#import <objc/objc-runtime.h>
#endif 
@implementation NSMethodSignature(types)

-(const char*)methodReturnType_1
{
    return "@";
}

#if 0
//#if Darwin
-(const char*)types
{
    return _types;
}
#endif 

@end

#if ! TARGET_OS_IPHONE

@implementation NSObject(methodAliasing)

+(void)addMethod:(IMP)method forSelector:(SEL)selector types:(const char*)types
{

	NSLog(@"addMethod:...");
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
	class_addMethod((Class)self ,selector,method,types);
#else
	   struct objc_method_list meth_list;

    memset( &meth_list, 0, sizeof meth_list );
    meth_list.method_count=1;
    meth_list.method_list[0].method_name=selector;
    meth_list.method_list[0].method_imp=method;
    meth_list.method_list[0].method_types=(char*)types;
    class_addMethods(self, &meth_list);
#endif	
}

/*"
   Method aliasing allows use of appropriate selector names without a run-time penalty.
"*/
+(void)aliasInstanceMethod:(SEL)old to:(SEL)new in:(Class)newClass
{
	[newClass addMethod:[self instanceMethodForSelector:old] forSelector:new types:(char*)[[self instanceMethodSignatureForSelector:old] types]];
}

+(void)aliasMethod:(SEL)old to:(SEL)new in:(Class)newClass
{
	[newClass addMethod:[self methodForSelector:old] forSelector:new types:(char*)[[self methodSignatureForSelector:old] types]];
}

+(void)aliasInstanceMethod:(SEL)old to:(SEL)new
{
    [self aliasInstanceMethod:old to:new in:self];
}

@end

#endif 

extern void *objc_msgForward( id target, SEL _cmd, ... );

@implementation NSObject(defaultedVoidMethod)

static void doNothing() { }
static BOOL returnYes() { return YES; }
static BOOL returnNo() { return NO; }

-(IMP)methodForSelector:(SEL)sel withDefault:(IMP)defaultMethod
{
	IMP result = defaultMethod;
	if ( [self respondsToSelector:sel] ) {
		IMP theMethod = [self methodForSelector:sel];
		if ( theMethod != (IMP)NULL ) {
			result = theMethod;
		}
	}
//	NSLog(@"IMP for -[%@ %@] with default %x = %x",[self class],NSStringFromSelector(sel),result,defaultMethod);
	return result;
}


-(IMP)defaultedVoidMethodForSelector:(SEL)sel
{
	return [self methodForSelector:sel withDefault:(IMP)doNothing];
}

-(IMP)boolMethodForSelector:(SEL)sel defaultValue:(BOOL)defaultValue
{
 	return [self methodForSelector:sel withDefault:defaultValue ? (IMP)returnYes : (IMP)returnNo];
}

@end

@implementation NSObject(instanceSize)

+(int)instanceSize
{

#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 ) || TARGET_OS_IPHONE
	return class_getInstanceSize( self ) ;
#else
#warning no class_getInstanceSize, getting instance size directly from class!
	 struct objc_class *class_def=(struct objc_class*)self;
	return class_def->instance_size;
#endif
}

@end
#if 1
@interface NSObjectInstanceSizeTesting:NSObject {}
@end
@implementation NSObjectInstanceSizeTesting 

+(void)testObjectInstanceSize
{
	INTEXPECT( [NSObject instanceSize], sizeof( void*) , @"NSObject");
	INTEXPECT( [MPWObject instanceSize], sizeof( void*) + 8 , @"MPWObject");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testObjectInstanceSize",
		nil];
}

@end
#endif