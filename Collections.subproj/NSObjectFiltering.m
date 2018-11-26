//
//  NSObjectFiltering.m
//  MPWFoundation
//
//  Created by marcel on Sun Aug 26 2001.
/*  
    Copyright (c) 2001-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import "NSObjectFiltering.h"
#import <MPWFoundation/MPWEnumSelectFilter.h>
#import <MPWFoundation/MPWEnumFilter.h>
#import <MPWFoundation/MPWTrampoline.h>
//#import "MPWMsgExpression.h"

@implementation NSObject(filtering)
/*"
    Higher order messaging operations for all objects.  Higher order message sends are
    normal messages that are sent multiple times due to the fact that they were
    preceded by a prefixMessage and either their receiver or at least on of their
    arguments is variable

      [[someObject prefixMessage] messsageToSend:argument1 with:argument2 ...];
  
    The prefixMessage prepares the 
"*/

-_filterWithSelector:(SEL)selector class:(Class)filterClass
{
    id trampoline = [MPWTrampoline trampoline];
    id filter = [filterClass quickFilter];

#if defined(VERBOSEDEBUG) && 0
    if ( localDebug ) {
        NSLog(@"got filter %@",filter);
//        NSLog(@"got trampoline %@",trampoline);
    }
#endif
    [trampoline setXxxTarget:filter];
    [trampoline setXxxSelector:selector];
    [filter setSource:[self each]];
#if defined(VERBOSEDEBUG) && 0
    if ( localDebug ) {
        NSLog(@"did set filter's source filter now %@",filter);
    }
#endif
/*
    NSLog(@"got here");
    NSLog(@"filter = %@",filter);
    NSLog(@"trampoline = %@",trampoline);
*/
    if ( [filter isValid] ) {
        return trampoline;
    } else {
        return nil;
    }
}

-_filterWithSelector:(SEL)selector
{
	return [self _filterWithSelector:selector class:[MPWEnumFilters class]];
}

-do
/*"
    Ignore the results of the message-pattern.

"*/
{
    return [self _filterWithSelector:@selector(doInvocation:)];
}

-selectArg:(int)n
{
    id trampoline = [self _filterWithSelector:@selector(selectInvocation:) class:[MPWEnumSelectFilter class]];
    [[trampoline xxxTarget] setResultSelector:n];
    return trampoline;
}

-select
{
    return [self selectArg:1];
}

-reject:(int)n
{
    id trampoline = [self _filterWithSelector:@selector(rejectInvocation:) class:[MPWEnumSelectFilter class]];
    [[trampoline xxxTarget] setResultSelector:n];
    return trampoline;
}

-reject
{
    return [self reject:1];
}

-collect
{
    return [self _filterWithSelector:@selector(collectInvocation:)];
}

-reduce
{
    return [self _filterWithSelector:@selector(reduceInvocation:)];
}

-selectFirst
{
    return [self _filterWithSelector:@selector(selectFirstInvocation:) class:[MPWEnumSelectFilter class]];
}

-selectWhereValueForKey:aKey
{
    id trampoline = [self select];
    [trampoline xxxSetTargetKey:aKey];
    return trampoline;
}

-selectWhereValueForKey:aKey isEqual:otherObject
{
    return [[self selectWhereValueForKey:aKey] __isEqual:otherObject];
}

-each
{
    return self;
}

-id_isEqual:otherObject
{
    return [self isEqual:otherObject] ? self : nil;
}


-filter
{
    return [self collect];
}

#if 0
-(int)exprValWithSelf:expr
{
    int result;
    [expr setReceiver:self];			//	assumes receiver is arg, OK for now
    result = (int)[expr eval];
    return result;
}
#endif


@end

