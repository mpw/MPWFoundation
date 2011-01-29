/*

  MPWWorkQueue.m
  MPWFoundation

  Copyright (c) 2010 by Marcel Weiher. All rights reserved.

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

//

#import "MPWWorkQueue.h"
#import "FIFO.h"
#import "MPWLockFreeFIFO.h"
#import "AccessorMacros.h"
#import "DebugMacros.h"
#import <Foundation/Foundation.h>
#import "MPWTrampoline.h"
#import "MPWStream.h"

@interface MPWWorkItem : MPWObject
{
	id queue;
	id invocation;
	id target;
}	
+workItemForObject:targetObject andQueue:aQueue;
+workItemForObject:targetObject;
-(void)performJob;

@end

@implementation MPWWorkQueue

idAccessor( jobs, setJobs )
idAccessor( completedJobs, setCompletedJobs )
intAccessor( workerCount, setWorkerCount )

static id sentinel=nil;

+(void)initialize
{
	if (!sentinel) {
		sentinel=[[NSObject alloc] init];
	}
}

-initWithWorkerCount:(int)count
{
	self=[super init];
#if ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
	[self setJobs:[MPWLockFreeFIFO fifo:200]];
#else
	[self setJobs:[FIFO fifo:200]];
#endif	
	[self setCompletedJobs:[FIFO fifo:100]];
	[self setWorkerCount:count];
	jobsWritten=0;
	jobsCompleted=0;
	return self;
}

+(int)defaultWorkerCount
{
	return 4;
}

#if ! TARGET_OS_IPHONE

+defaultQueue
{
	static id defaultQueue=nil;
	@synchronized(self) {
		if (!defaultQueue) {
			defaultQueue=[[MPWWorkQueue alloc] initWithWorkerCount:[self defaultWorkerCount]];
			[defaultQueue runJobs];
		}
	}
	return defaultQueue;
}

#endif

-(void)addJob:aJob
{
//	NSLog(@"put a job: %p",aJob);
	if (aJob != nil ) {
		jobsWritten++;
		[jobs put:aJob];
	} else {
		[jobs put:sentinel];
	}
}

-(void)waitUntilAllJobsDone
{
//	NSLog(@"wait for jobs: %d",jobsWritten);
	while ( jobsWritten > jobsCompleted ) {
		id completed=[completedJobs get];
		if ( completed ) {
			jobsCompleted+=[completed intValue];
//			NSLog(@"got completed: %d",jobsCompleted);
		} else { 
			usleep( 10 );
		}
	}
}

-(void)runJobs
{
	int i;
	for (i=0;i<workerCount;i++) {
		[NSThread detachNewThreadSelector:@selector(drainJobs) toTarget:self withObject:nil];
	}
}

-(void)completeJob:aJob
{
	[completedJobs put:aJob];
}

-getJob
{
	id aJob;
	aJob=[jobs get];
//	NSLog(@"get a job: %p",aJob);
//	NSLog(@"get a job: %@",aJob);
	return aJob;
}

#if ! TARGET_OS_IPHONE

-(void)drainJobs
{
	id pool=[NSAutoreleasePool new];
	MPWWorkItem *aJob=nil;
	int completionCount=0;
	NS_DURING
	do {
		aJob = [self getJob];
		if ( aJob != sentinel ) {
				[aJob performJob];
			completionCount++;
		}
	} while ( aJob && aJob != sentinel  );
	NS_HANDLER
	NS_ENDHANDLER
	[completedJobs put:[[NSNumber alloc] initWithInt:completionCount]];
	[pool release];
	if ( aJob == sentinel ) {
		[jobs put:sentinel];	//	other workers...
	}
	NSLog(@"thread %x completionCount %d",[NSThread currentThread],completionCount);
}

#endif

-(void)dealloc
{
	[jobs release];
	[completedJobs release];
	[super dealloc];
}

@end
@implementation MPWWorkItem


-initWithObject:anObject queue:aQueue
{
	self=[super init];
	target=[anObject retain];
	queue=[aQueue retain];
	return self;
}

+workItemForObject:anObject andQueue:aQueue
{
	return [[[self alloc] initWithObject:anObject queue:aQueue] autorelease];
}
+workItemForObject:targetObject
{
	return [self workItemForObject:targetObject andQueue:[MPWWorkQueue defaultQueue]];
}

-(void)setAndPerformInvocation:anInvocation
{
	[anInvocation setTarget:target];
	invocation=[anInvocation retain];
	[queue addJob:self];
}


-(void)performJob
{
	[invocation invoke];
}

-(void)dealloc
{
	[super dealloc];
}

-(BOOL)respondsToSelector:(SEL)selector
{
	return [target respondsToSelector:selector];
}

-(NSMethodSignature*)methodSignatureForHOMSelector:(SEL)sel
{
	return [target methodSignatureForSelector:sel];
}

@end

@implementation NSObject(createWork)

-asyncJob
{
	return [MPWTrampoline trampolineWithTarget:[MPWWorkItem workItemForObject:self] selector:@selector(setAndPerformInvocation:)];
}

-asyncJob:queue
{
	return [MPWTrampoline trampolineWithTarget:[MPWWorkItem workItemForObject:self andQueue:queue] selector:@selector(setAndPerformInvocation:)];
}

@end


@implementation MPWWorkQueue(testing)


+(void)testThatQueueGetsWorkDoneAtAll
{
	FIFO* targetFifo=[FIFO fifo:10];
	NSMutableSet* resultSet=[NSMutableSet set];
	int i;
	[[@"hello" asyncJob] writeOnStream:targetFifo];
	[[@"world" asyncJob] writeOnStream:targetFifo];
	for ( i=0;i<2;i++) {
		[resultSet addObject:[targetFifo get]];
	}
	INTEXPECT( [resultSet count],2, @"");
	NSAssert( [resultSet containsObject:@"hello"] , @"resultSet should contain 'hello'" );
	NSAssert( [resultSet containsObject:@"world"] , @"resultSet should contain 'world'" );
	NSLog(@"resultSet: %@",resultSet);
}

+testSelectors
{
	return [NSArray arrayWithObjects:@"testThatQueueGetsWorkDoneAtAll",
			nil];
}

@end
