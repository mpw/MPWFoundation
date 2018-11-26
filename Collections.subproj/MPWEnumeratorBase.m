/* MPWEnumeratorBase.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWEnumeratorBase.h"

@implementation MPWEnumeratorBase

+enumerate:source
{
    return [[[self alloc] initWithSourceEnumerator:source] autorelease];
}

-initWithSourceEnumerator:anEnumerator
{
    self = [super init];
    sourceEnumerator = [anEnumerator retain];
    return self;
}

-(void)dealloc
{
    [sourceEnumerator release];
    [super dealloc];
}

-nextObject
{
    return [sourceEnumerator nextObject];
}

-allObjects
{
    id result=[NSMutableArray array];
    id next;
    while ( next=[self nextObject] ) {
        [result addObject:next];
    }
    return result;
}


@end
