/* MPWEnumeratorBase.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@protocol BaseEnumeration

-nextObject;

@end

@protocol EnumeratorFilter <BaseEnumeration>

+enumerate:source;
-initWithSourceEnumerator:anEnumerator;
-(NSArray*)allObjects;


@end

@interface MPWEnumeratorBase : NSObject <EnumeratorFilter>
{
    id	sourceEnumerator;
}


@end
