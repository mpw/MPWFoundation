/* NSInvocationAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSInvocationAdditions.h"
#import "NSInvocationAdditions_lookup.h"

@implementation NSInvocation(OneStepCreation)
/*"
    Convenience methods for working with NSInvocations used within the framework.
"*/

+invocationWithTarget:newTarget andSelector:(SEL)newSel
{
    id inv=[self invocationWithMethodSignature:[newTarget methodSignatureForSelector:newSel]];
    [inv setTarget:newTarget];
    [inv setSelector:newSel];
    return inv;
}

-returnValueAfterInvokingWithTarget:target
{
    id retval=nil;
    [self invokeWithTarget:target];
    long returnLength=[[self methodSignature] methodReturnLength];
    if (returnLength > 0 && returnLength <= sizeof retval) {
        [self getReturnValue:&retval];
    }
    return retval;
}


-description1
{
	return [NSString stringWithFormat:@"<%@:%p: -[%@:%p %@]>",[self class],self,[[self target] class],[self target],NSStringFromSelector([self selector])];
}


@end
