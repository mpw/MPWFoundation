/*
    Copyright (c) 2001-2017 by Marcel Weiher. All rights reserved.

R

*/

#if !TARGET_OS_IPHONE


#import <Foundation/NSString.h>
#import "MPWObject.h"

@interface MPWUniqueString : NSString
{
	const char	*data;
	long	len;
    long	hash;
	BOOL	freeWhenDone;
}

-initWithPrivateCString:(const char*)cStr length:(NSUInteger)newLen;
-(NSUInteger)hash;
-(BOOL)isEqual:other;
-(const char*)cString;
-(NSUInteger)length;
//-(NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)enc;
-uniqueString;
-(void)writeOnByteStream:aStream;

@end

MPWUniqueString *MPWUniqueStringWithCString( const char *string, long len );
MPWUniqueString *MPWUniqueStringWithUnichars( const unichar *string, long len );
MPWUniqueString *MPWUniqueStringWithString( id string );

@interface NSString(unique)
-uniqueString;
@end

#endif

