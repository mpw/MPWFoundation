/* MPWEnumFilter.h Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/


#import "MPWObject.h"
#import <Foundation/Foundation.h>


@interface MPWEnumFilters : MPWObject
{
//    Class isa;
    id	source;
    NSInvocation *invocation;
    id	arguments[10];
    int argumentCount;
    int	variableArguments;
    int variableArgumentStart;
    IMP	argumentNextObject[10];
    int	variableArgumentIndex[10];
    id	variableArgumentSource[10];

    Class	targetClass;
    SEL		targetSelector;
    IMP		targetFilterImp;
    IMP		selfDoFilter;
    int		resultSelector;
    BOOL	delayedEvaluation;
    IMP         processResult;
	id		key;
}

+quickFilter;
-(void)setResultSelector:(int)whichArg;
-(void)setSource:newSource;
-(SEL)mapSelector:(SEL)aSelector;
-(void)setKey:(id)newVar;
@end

//--- define dummy prefixes for common selector returning BOOL so these can be used
//--- with select-filtering.

@interface NSObject(selection)
-__isEqual:otherObject;
-__isEqualToString:otherObject;
-__hasPrefix:otherObject;
-__containsObject:otherObject;
-__characterIsMember:(unichar)theChar;
-__isOneWay;
-__isNotNil;
-__isMemberOfClass:(Class)aClass;
-__isKindOfClass:(Class)aClass;
@end


