/* MPWRuntimeAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
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

#if 0
// FIXME:  redo with objc2 functions, allows direct access to method types


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
#endif

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

+(long)instanceSize
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
