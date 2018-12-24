/* MPWEnumFilter.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWFoundation/MPWObject.h"



@interface MPWEnumFilters : MPWObject
{
    id              source;
    NSInvocation    *invocation;
    id              arguments[10];
    int             argumentCount;
    int             variableArguments;
    int             variableArgumentStart;
    IMP0            argumentNextObject[10];
    int             variableArgumentIndex[10];
    id              variableArgumentSource[10];

    Class           targetClass;
    SEL             targetSelector;
    IMP0            targetFilterImp;
    IMP0            selfDoFilter;
    int             resultSelector;
    BOOL            delayedEvaluation;
    IMP0            processResult;
	id              key;
}

+quickFilter;
-(void)setResultSelector:(int)whichArg;
-(void)setSource:newSource;
-(SEL)mapSelector:(SEL)aSelector;
-(void)setKey:(id)newVar;
-selectInvocation:(NSInvocation*)newInvocation;
-(void)doInvocation:(NSInvocation*)newInvocation;
-rejectInvocation:(NSInvocation*)newInvocation;
-collectInvocation:(NSInvocation*)newInvocation;
-reduceInvocation:(NSInvocation*)newInvocation;
-selectFirstInvocation:(NSInvocation*)newInvocation;
@end

//--- define dummy prefixes for common selector returning BOOL so these can be used
//--- with select-filtering.

@interface NSObject(selection)
-__isEqual:otherObject;
-__isEqualToString:otherObject;
-__hasPrefix:otherObject;
-__containsObject:otherObject;
//-__characterIsMember:(unichar)theChar;
-__isOneWay;
-__isNotNil;
-__isMemberOfClass:(Class)aClass;
-__isKindOfClass:(Class)aClass;



@end


