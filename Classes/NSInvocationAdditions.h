/* NSInvocationAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@interface NSInvocation(OneStepCreation)

//inline IMP objc_msg_lookup( id obj, SEL msg );
+invocationWithTarget:newTarget andSelector:(SEL)newSel;
//-(void)setReturnType:(int)returnType;
-returnValueAfterInvokingWithTarget:target;

@end
