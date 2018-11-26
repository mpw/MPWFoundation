/*
  
    MPWFuture.h
  
    Created by Marcel Weiher on 28/03/2005.
    Copyright (c) 2005-2017 by Marcel Weiher. All rights reserved.

R

*/


#import <Foundation/Foundation.h>


@interface MPWFuture : NSProxy {
	id					target;
	NSInvocation*		invocation;
	id					_result;
	NSConditionLock*	lock;
	BOOL				running;
}

//-(void)runWithInvocation:(NSInvocation*)invocation;
-result;
-(void)performJob;
@end

@interface NSObject(future)
-future;
@end

