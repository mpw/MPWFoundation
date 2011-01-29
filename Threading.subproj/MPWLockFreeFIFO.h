//
//  MPWLockFreeFIFO.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/23/07.
//  Copyright 2010-2011 by Marcel Weiher. All rights reserved.
//

#import "MPWObject.h"


@interface MPWLockFreeFIFO : MPWObject {
	id	*nodes;
	int capacity;
	int head,tail;
	id  vnull;

}

+fifo:(NSUInteger)capacity;
-init;
-initWithCapacity:(NSUInteger)newCapacity;
-(BOOL)tryEnqueue:object;
-(void)enqueue:object;
-(void)put:object;
-dequeue; // Blocks until there is an object to return
-get;
-(void)dealloc;
-(int)count;		// may be inaccurate by small number


@end
