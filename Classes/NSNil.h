/* NSNil.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@interface NSNil : NSObject
{

}

+nsNil;

#if !TARGET_OS_IPHONE
+(void)setNilHandler;
+(void)unsetNilHandler;
#endif

@end

@interface NSObject(nilTesting)
-(BOOL)isNotNil;
-(BOOL)isNil;
-(id)ifNil:aBlock;
-(id)ifNotNil:aBlock;
@end

