/* MPWEnumeratorEnumerator.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWEnumeratorEnumerator.h"

@implementation MPWEnumeratorEnumerator

-nextObject
{
    return [[sourceEnumerator nextObject] nextObject];
}

@end

