/* MPWEnumSelectFilter.m Copyright (c) 1998-1999 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>
#import "MPWEnumSelectFilter.h"
#import "MPWObjectCache.h"

@implementation MPWEnumSelectFilter

CACHING_ALLOC( quickFilter, 30, NO )

- (NSMethodSignature *)methodSignatureForHOMSelector:(SEL)aSelector
{
//	NSLog(@"will return faked method signature");
	return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
}



+testSelectors
{
	return @[];         // no tests (and don't want superclass tests)
}


@end
