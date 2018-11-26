/* MPWEnumeratorSource.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWEnumeratorSource.h"

@implementation MPWEnumeratorSource

-nextObject
{
    return [[NSArray arrayWithObject:[sourceEnumerator nextObject]] objectEnumerator];
}


@end
