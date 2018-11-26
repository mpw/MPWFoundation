//
//  NSObjectFiltering.h
//  MPWFoundation
//
//  Created by marcel on Sun Aug 26 2001.
/*  
    Copyright (c) 2001-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import <Foundation/Foundation.h>

@protocol HOM

-collect;
-select;
-selectFirst;
-reject;
-do;
-selectWhereValueForKey:aKey;
-selectWhereValueForKey:aKey isEqual:otherObject;

@end


@interface NSObject(filtering) <HOM>
-each;
-filter;
-collect;
-selectArg:(int)n;
-select;
-reject:(int)n;
-reject;
-reduce;
-do;
-selectWhereValueForKey:aKey;
-id_isEqual:otherObject;
#if 0
-(int)exprValWithSelf:expr;
#endif

@end
