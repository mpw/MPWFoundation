/*
   	MPWMsgExpression.h created by marcel on Fri 16-Jul-1999
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

R

*/


#import <Foundation/Foundation.h>

@interface MPWMsgExpression : NSInvocation
{
    IMP		cachedImp,evalFun;
    Class	cachedClass,cachedEvalClass;
    id		receiver;
#ifdef Darwin
    SEL		selector;
#endif    
    id		boundArgs[8];
    char	argTypes[8];
    int		argumentCount;
    BOOL	prebound;
    @public
    IMP		eval;
}

-receiver;


@end

@interface NSObject(expressionCreation)
-quote;

@end

@interface NSInvocation(expressionSupport)

-(void)setReceiver:newReceiver;
-eval;
-xxxEval:environment;

@end
