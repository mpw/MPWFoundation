//
//	FIFO.m
//
//
/*
    Copyright (c) 1997-2011 by Marcel Weiher. All rights reserved.

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


//---	class definition

#import "FIFO.h"

//---	imported class

#import <Foundation/NSLock.h>
#import <Foundation/NSObject.h>
#import <MPWFoundation/MPWStream.h>

#import "DebugMacros.h"

//---	standard C includes

#include <stdlib.h>
#include <unistd.h>

@implementation FIFO 

#define	NO_DATA	1
#define	DATA_AVAILABLE	2
#define	NO_OVERRUN	2
#define	DATA_FULL	3


#define	_INDEX_OF( element,base,capacity )	((base+(element)) < capacity ? (base+(element)) : (base+(element)) - capacity)
#define	INDEX_OF( element )	_INDEX_OF( element, self->base, self->capacity)
//-------------------------------------
//
//	init:
//
//	initializes the FIFO
//	with the specified
//	capacity
//
//-------------------------------------	

+fifo:(unsigned)count
{
    return [[[self alloc] init:count] autorelease];
}

-init:(unsigned )count
{
	[super init];
	condition_lock=[[NSConditionLock alloc] initWithCondition:NO_DATA];
	capacity=count+20;
	fifoSize=count;
	size=0;
	base=0;
	data=calloc( capacity+2, sizeof( id ) );
	return self;
}

-init
{
	return [self init:60];
}

-(void)grow
{
	int i;
	int	newSize=(fifoSize+2)* 2;
	int newCapacity = newSize + 20;
	id *new_data = calloc( newCapacity , sizeof(id)  );
	for (i=0;i<size;i++) {
		new_data[ i ]=data[INDEX_OF(i)];
	}
	base=0;
	fifoSize=newSize;
	free(data);
	data=new_data;
	capacity=newCapacity;
}

//-------------------------------------
//
//	put:
//
//	place an object in the
//	back of the FIFO.
//
//	Block on entry if the
//	FIFO is full.
//
//	On exit, inform any blocked
//	readers that data is now 
//	available.
//
//	Issue:	there should be 
//	mode that allows blocking
//	on exit if the FIFO is full.
//
//-------------------------------------	


-(void)put:anObject
{
//	DPRINTF2("object is %p %s\n",anObject,
//		[[[anObject class] description] cString]);
	[condition_lock lock];
	if ( [self isFull] ) {
		[self grow];
	}
	data[ INDEX_OF(size) ] = [anObject retain];
	size++;
//      [self dump];
	[condition_lock unlockWithCondition:DATA_AVAILABLE];
//       DPRINTF3("did put object %p into FIFO %p, size now %d\n",
//               anObject,self,size);
}

//-------------------------------------
//
//	getObjectNoBlock()
//
//	shared access routine
//	returns + removes the object
//	 at front of the FIFO, or 
//	returns nil if the
//	FIFO is empty.
//
//-------------------------------------	



static inline id getObjectNoBlock( FIFO* self )
{
    id retval=nil;

    if ( self->size > 0 )
    {
        //---	there is at least one object in the FIFO
        //---	go take it out

        retval=self->data[ INDEX_OF( 0 ) ];
        self->size--;
        self->base++;
        
        //---	wrap-around the object index
        //---	(FIFO is implemented as a ring
        //---	buffer).

        if ( self->base >= self->capacity )
            self->base=0;
    }
    else
        retval=nil;
    return [retval autorelease];;
}
	
//-------------------------------------
//
//	get
//
//	Get an object from the
//	front of the queue.
//
//	Wait as long as is necessary.
//
//	Unblock any blocked writers.
//-------------------------------------	

-get
{
	id retval;
//	DPRINTF1("size before: %d\n",size);
	[condition_lock lockWhenCondition:DATA_AVAILABLE];
//      [self dump];
	retval=getObjectNoBlock( self );
//      [self dump];
	[condition_lock unlockWithCondition:size<=0 ? NO_DATA : DATA_AVAILABLE];
//     	DPRINTF2("got object %p of class %s\n",retval,
//			[[[retval class] description] cString]);
//	cthread_yield();
	return retval;
}		

//-------------------------------------
//
//	peek
//
//	Return the  object at the
//	front of the queue, without
//	dequeuing it.
//
//	Wait as long as is necessary.
//
//-------------------------------------	

-peek
{
	id retval;

	[condition_lock lockWhenCondition:DATA_AVAILABLE];
	
	retval=data[ INDEX_OF( 0 ) ];

	[condition_lock unlock];
	return retval;
}		

//-------------------------------------
//
//	peekNoBlock
//
//	Return the  object at the
//	front of the queue, without
//	dequeuing it.
//
//	Always returns immediately,
//	returning nil if the FIFO is empty.
//
//-------------------------------------	


-peekNoBlock
{
	id retval;
	[condition_lock lock];
	if (size>0)
		retval=data[INDEX_OF(0)];
	else
		retval=nil;
	[condition_lock unlock];
	return retval;
}


-getNoBlock
{
	id retval;
	[condition_lock lock];
	retval=getObjectNoBlock( self );
	[condition_lock unlock];
	return retval!=nil ? retval : nil;
}



-(BOOL)isFull
{
	return size >= capacity;
}

-(BOOL)isEmpty
{
	return size == 0;
}
-postException:(int)newException
{
//	[condition_lock postException:newException];
	return self;
}

-releaseObjects
{
	id anObject;
	[condition_lock lock];
	while ( anObject = getObjectNoBlock( self ) )
		[anObject release];
	[condition_lock unlock];
	return self;
}


-(void)dealloc
{
	[self releaseObjects];
	[condition_lock release];
	free(data);
	[super dealloc];
}

-(NSUInteger)count
{
	return size;
}
-objectAtIndex:(unsigned)position
{
	if ( position < size )
		return data[INDEX_OF( position )];
	else
		return nil;
}	

-(void)waitForEmpty
{
	[condition_lock lockWhenCondition:NO_DATA];
	[condition_lock unlock];
}

-(void)lockEmpty
{
	[condition_lock lockWhenCondition:NO_DATA];
}

-(void)unlock
{
	[condition_lock unlock];
}	

-nextObject
{
    return [self get];
}

-(void)writeObject:anObject
{
    [self put:anObject];
}

-(void)writeData:aData
{
    [self put:aData];
}

-(void)close:(int)n
{
    [self writeObject:nil];
    [self waitForEmpty];
}

-(void)flush:(int)n
{
    [self waitForEmpty];
}

-(void)writeOnMPWStream:aStream
{
    [aStream writeEnumerator:self];
}

-(NSArray*)allObjects
{
    NSMutableArray *array=[NSMutableArray array];
    id nextObject;
    while ( nil!=(nextObject=[self nextObject])){
        [array addObject:nextObject];
    }
    return array;
}

-(NSArray*)allAvailableObjects
{
    NSMutableArray *array=[NSMutableArray array];
    id nextObject;
    while ( nil!=(nextObject=[self getNoBlock])){
        [array addObject:nextObject];
    }
    return array;
}

-(void)readAllObjectsFromEnumerator:anEnumerator
{
    id nextObject;
    
    [anEnumerator retain];
    do {
        NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
        [self put:nextObject=[anEnumerator nextObject]];
        [pool release];
    } while ( nextObject != nil );
    [anEnumerator release];
}


+threadedEnumeratorWithEnumerator:anEnumerator
{
    id fifo=[[self alloc] init];
    [NSThread detachNewThreadSelector:@selector(readAllObjectsFromEnumerator:)
                                 toTarget:fifo withObject:anEnumerator];
    return [fifo autorelease];
}

-(void)flush
{
    ;
}

-(void)close
{
    ;
}

@end

@implementation FIFO(testing)

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"dualThreadStream",@"singleThreadStream",nil
    ];
}

+(void)singleThreadStream
{
    id fifo=[[[self alloc] init:20] autorelease];
    id stream=[MPWStream streamWithTarget:fifo];
    id inData=[NSMutableArray arrayWithObjects:@"one",@"two",@"three",nil];
    id outData;
    int i;
    for (i=0;i<100;i++) {
//        [inData addObject:[NSString stringWithFormat:@"%d",i]];
        [inData addObject:@"more"];
    }
    [stream writeObject:[inData objectEnumerator]];
    outData=[fifo allAvailableObjects];
    NSAssert2( [inData isEqual:outData], @"output:'%@' not equal to input:'%@'",outData,inData);
}

+(void)dualThreadStream
{
    id fifo=[[[self alloc] init:10] autorelease];
    id stream=[MPWStream streamWithTarget:fifo];
    id inData=[NSMutableArray arrayWithObjects:@"one",@"two",@"three",nil];
    id outData;
    int i;
    for (i=0;i<100;i++) {
//        [inData addObject:[NSString stringWithFormat:@"%d",i]];
        [inData addObject:@"more"];
    }
    [NSThread detachNewThreadSelector:@selector(writeObjectAndClose:)
                             toTarget:stream
                           withObject:[inData objectEnumerator]];

    outData=[fifo allObjects];
	usleep(1000);
	INTEXPECT( [fifo count], 0 , @"fifo should be empty after allObjects");
	INTEXPECT( [inData count], [outData count], @"didn't get the same number of items out of the queue I should have put in" );
    NSAssert2( [inData isEqual:outData], @"output:'%@' not equal to input:'%@'",outData,inData);
}


@end



