//
//  MPWFastInvocation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 27/3/07.
//  Copyright 2010-2017 by Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWObject.h>
#import <Foundation/Foundation.h>

@protocol MPWEvaluation
-(id)evaluateOnObject:newTarget parameters:(NSArray*)parameters;
@end

@interface MPWFastInvocation : MPWObject <MPWEvaluation> {
	@public
	IMP0  invokeFun;
}

#define	INVOKE( inv )	((inv)->invokeFun( (inv), @selector(resultOfInvoking))) 

+quickInvocation;
-target;
-(void)invoke;
-resultOfInvoking;
-(void)setArgument:(void*)buffer atIndex:(NSInteger)argIndex;
-(void)setTarget:newTarget;
-(SEL)selector;
-(void)setSelector:(SEL)newSelector;
-resultOfInvokingWithArgs:(id*)newArgs count:(int)count;
-(void)setUseCaching:(BOOL)doCaching;
-returnValueAfterInvokingWithTarget:aTarget;

@end

@interface NSInvocation(convenience)

-resultOfInvoking;

@end
