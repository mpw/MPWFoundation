/* MPWSubData.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/MPWObject.h>

@interface MPWSubData : NSString <NSCoding>		//	make these NSString compatible
{
    int		__retainCount;						//	also make them MPWObject compatible
	int		flags;
    NSData*	myData;
    const void *myBytes;
    long myLength;
    BOOL	mustUnique,interned;
}

-initWithData:(NSData*)data bytes:(const char*)bytes length:(long)len;
-reInitWithData:(NSData*)data bytes:(const char*)bytes length:(long)len;
-(const void*)bytes;
-(const char*)cString;
-(NSUInteger)length;
boolAccessor_h( mustUnique, setMustUnique )
-originalData;
-(unsigned long)offset;

@end

@interface NSObject(descr)

-(NSString*)descr;

@end

@interface NSData(mpwsubdata)
-(MPWSubData*)mpwSubdataWithRange:(NSRange)theRange;

@end
