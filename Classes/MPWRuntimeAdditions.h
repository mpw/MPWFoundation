/* MPWRuntimeAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
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
//+(void)aliasInstanceMethod:(SEL)old to:(SEL)newSel in:(Class)newClass;
//+(void)aliasMethod:(SEL)old to:(SEL)newSel in:(Class)newClass;
//+(void)aliasInstanceMethod:(SEL)old to:(SEL)newSel;
@end

@interface NSObject(defaultedVoidMethod)

-(IMP)defaultedVoidMethodForSelector:(SEL)sel;
-(IMP)boolMethodForSelector:(SEL)sel defaultValue:(BOOL)defaultValue;

@end


@interface NSObject(instanceSize)

+(long)instanceSize;

@end
