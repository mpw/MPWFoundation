//
//  MPWLockFreeFIFO.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/23/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "MPWLockFreeFIFO.h"
#import <stdlib.h>
#include <unistd.h>

#include <libkern/OSAtomic.h>

#if ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )


@implementation MPWLockFreeFIFO

#define  VNULL(x)	(id)(x)
#define  casi( ptr, old , new )   OSAtomicCompareAndSwapInt( old, new, (void*)(ptr) )
#define  casp( ptr, old , new )   OSAtomicCompareAndSwapPtr( old, new, (void*)(ptr) )


+fifo:(NSUInteger)newCapacity
{
	return [[[self alloc] initWithCapacity:newCapacity] autorelease];
}

-(id)initWithCapacity:(NSUInteger)newCapacity {
  if (nil != (self = [super init])) {
	int i;
	capacity=newCapacity;
	head=0;
	tail=1;
	vnull=VNULL(1);
	nodes=malloc( sizeof(id) * (capacity+2));
	for (i=0;i<capacity;i++) {
		nodes[i]=VNULL(0);
	}
	nodes[0]=VNULL(1);
  }
  return self;
}

-init
{
	return [self initWithCapacity:100];
}

-(int)count
{
	int baseCount=(tail-head)-1;
	if ( head > tail ) {
		baseCount+=capacity;
	}
	return baseCount;
}

-(void)put:object
{
	[self enqueue:object];
}

-(void)enqueue:object
{
	int retryCount=1;
	while ( ![self tryEnqueue:object] ) {
//		pthread_yield();
		usleep( retryCount );
 #if 1
		retryCount++;
		if (( retryCount % 50 ) == 0 ) {
//			NSLog(@"retry enqueue %d, head=%d tail=%d count=%d",retryCount,head,tail,[self count]);
		}
#endif		
	}
}

#define NEXT_CELL( start )   (((start)+1) % capacity)

-(BOOL)tryEnqueue:(id)object {
//	NSLog(@"will try to enqueue: %@",object);
	while ( 1 ) {
		int old_tail;
		int new_tail;
		int temp;
		id tt;
//		NSLog(@"top of loop");
		old_tail=tail;
		new_tail=old_tail;
		tt=nodes[new_tail];
		temp=NEXT_CELL(new_tail);
//		NSLog(@"first try: head = %d tail=%d new_tail=%d temp=%d tt=%x nodes[%d]=%x",head,tail,new_tail,temp,tt,new_tail,nodes[new_tail]);
		while ( tt != VNULL(0) && tt != VNULL(1) ) {
//			NSLog(@"search for real tail (found a null)");
			if ( old_tail != head ) {
				break;
			}
			if (temp==head) {
				break;
			}
			tt=nodes[temp];
			new_tail=temp;
			temp=NEXT_CELL(new_tail);
//			NSLog(@"searching real tail, tail=%d new_tail=%d temp=%d tt=%x nodes[%d]=%x",tail,new_tail,temp,tt,new_tail,nodes[new_tail]);
		}
		if ( old_tail != tail ) {
//			NSLog(@"tail not up-to-date, retry");
			continue;
		}
		if ( temp == head ) {
//			NSLog(@"at head");
			new_tail=NEXT_CELL(temp);
			tt=nodes[new_tail];
			if ( tt != VNULL(0) && tt != VNULL(1) ) {
//				NSLog(@"queue full");
				return NO;			// queue full
			}
			if ( !new_tail) {
				vnull=tt;
			}
//			NSLog(@"update head");
			casi( &head, temp, new_tail );
			continue;
		}
		if ( old_tail != tail ) {
//			NSLog(@"tail not up to date, retry");
			continue;
		}
//		NSLog(@"at casp: tail=%d new_tail=%d temp=%d tt=%x nodes[%d]=%x nodes=%x, nodes+new_tail=%x",tail,new_tail,temp,tt,new_tail,nodes[new_tail],nodes,nodes+new_tail);
		if ( casp( &nodes[new_tail], tt , object ) ) {
//			if ( (temp%2) == 0 ) {
				casi( &tail, old_tail, temp );
//			}
//			NSLog(@"success enqueueing count %d",[self count]);
			return YES;
		} else {
//			NSLog(@"casp failed");
//			NSLog(@"failure with tail=%d new_tail=%d temp=%d tt=%x nodes[%d]=%x",tail,new_tail,temp,tt,new_tail,nodes[new_tail]);
		}
//		NSLog(@"fell through bottom of loop");
	}
	return NO;
}

-(id)tryDequeue {
	while ( YES ) {
		id  tnull=nil;
		int th=head;
		int temp=NEXT_CELL(th);
		id  tt=nodes[temp];
		while ( tt ==VNULL(0) || tt==VNULL(1)) {
			if ( th != head ) {
				break;
			}
			if (temp== tail ) {
				return nil;
			}
			temp=NEXT_CELL(temp);
			tt=nodes[temp];
		}
		if ( th != head ) {
			continue;
		}
		if ( temp == tail ) {
			casi( &tail, temp, NEXT_CELL(temp));
			continue;
		}
		if ( temp ) {
			if ( temp < th ) {
				tnull=nodes[0];
			} else {
				tnull=vnull;
			}
		} else {
			tnull=(id)((NSUInteger)vnull ^ 1);
		}
		if ( th != head )  {
			continue;
		}
		if ( casp( nodes+temp, tt , tnull )) {
			if ( !temp ) {
				vnull=tnull;
			}
//			if ( (temp % 2 )==0 ) {
//				NSLog(@"update head from reader");
				casi( &head, th, temp );
//			}
			return tt;
		}
	}
	return nil;
}

-dequeue
{
	id result;
	int retryCount=1;
	while ( !(result=[self tryDequeue])) {
//		pthread_yield();
		usleep(retryCount );
#if 1
		retryCount++;
		if (( retryCount % 50 ) == 0 ) {
//			NSLog(@"retry dequeue %d, head=%d tail=%d count=%d",retryCount,head,tail,[self count]);
		}
#endif
	} 
	return result;
}

-get {   return [self dequeue]; }

-(void)dealloc {
  if ( nodes )  free(nodes);
  [super dealloc];
}



@end

#endif
