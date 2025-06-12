/* MPWRuntimeAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>



@interface NSObject(methodAliasing)
+(void)addMethod:(IMP)method forSelector:(SEL)selector types:(const char*)types;
@end

@interface NSObject(defaultedVoidMethod)

-(IMP)defaultedVoidMethodForSelector:(SEL)sel;
-(IMP)boolMethodForSelector:(SEL)sel defaultValue:(BOOL)defaultValue;

@end


@interface NSObject(instanceSize)

+(long)instanceSize;

@end
