//
//  MPWFileChangesStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 12.05.21.
//

#import "MPWFileChangesStream.h"

@interface MPWFileChangesStream()

@property (nonatomic,assign) FSEventStreamRef streamRef;

@end


@implementation MPWFileChangesStream
{
    BOOL scheduled;
}

-(void)setPath:(NSString*)path
{
    FSEventStreamContext context={0};
    context.info=self;
    self.streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                         (FSEventStreamCallback)&fsevents_callback,
                                         &context,
                                         (CFArrayRef)@[path],
                                         kFSEventStreamEventIdSinceNow,
                                         0.0001,
                                         kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents);
    //                                kFSEventStreamCreateFlagWatchRoot);
}

-(void)setReference:(id <MPWReferencing>)reference
{
    [self setPath:reference.path];
}

-(instancetype)initWithDirectoryPath:(NSString*)path
{
    self=[super init];
    [self setPath:path];
    return self;
}

-(void)scheduleInRunLoop:(NSRunLoop*)runLoop
{
    if (!scheduled) {
        FSEventStreamScheduleWithRunLoop(self.streamRef, runLoop.getCFRunLoop, kCFRunLoopDefaultMode);
        scheduled=YES;
    }

}

-(void)schedule
{
    [self scheduleInRunLoop:[NSRunLoop currentRunLoop]];
}

-(BOOL)start
{
    [self schedule];
    return FSEventStreamStart(self.streamRef);
}

-(void)stop
{
    FSEventStreamStop(self.streamRef);
}

static void
fsevents_callback(FSEventStreamRef streamRef, void *clientCallBackInfo,
                  int numEvents,
                  const char *const eventPaths[],
                  const FSEventStreamEventFlags *eventFlags,
                  const uint64_t *eventIDs)
{
    [(id)clientCallBackInfo fsEvents:numEvents paths:eventPaths flags:eventFlags];
}


-(void)fsEvents:(int)numEvents paths:(const char *const*) eventPaths flags:(const FSEventStreamEventFlags*)eventFlags
{
    for (int i=0; i < numEvents; i++) {
        @autoreleasepool {
            NSString *path=[NSString stringWithUTF8String:eventPaths[i]];
            MPWRESTVerb verb=(eventFlags[i] & kFSEventStreamEventFlagItemRemoved) ? MPWRESTVerbDELETE : MPWRESTVerbPUT;
            MPWRESTOperation *op=[MPWRESTOperation operationWithReference:path verb:verb];
            [self.target writeObject:op];
        }
    }
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWFileChangesStream(testing) 

+(void)testGotAnEvent
{
    NSMutableArray *result=[NSMutableArray array];
    MPWFileChangesStream *s=[[[MPWFileChangesStream alloc] initWithDirectoryPath:@"/tmp"] autorelease];
    
    [s retain];             // FIXME:  workaround for
    s.target=result;
    [s schedule];
    [s start];
    [NSTimer scheduledTimerWithTimeInterval:0.00001 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [@"test data" writeToFile:@"/tmp/MPWFileChangesStream_test.txt" atomically:NO encoding:NSASCIIStringEncoding error:nil];
    }];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    INTEXPECT(result.count,1,@"should have gotten a change");
    IDEXPECT([result.firstObject reference],@"/private/tmp/MPWFileChangesStream_test.txt",@"change");
    IDEXPECT([result.firstObject HTTPVerb],@"PUT",@"change");
    [result removeAllObjects];
    [NSTimer scheduledTimerWithTimeInterval:0.00001 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [@"test data" writeToFile:@"/tmp/MPWFileChangesStream_test.txt" atomically:YES encoding:NSASCIIStringEncoding error:nil];
    }];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    INTEXPECT(result.count,3,@"atomically is 3 changes instead of 1");
    [result removeAllObjects];
    [NSTimer scheduledTimerWithTimeInterval:0.00001 repeats:NO block:^(NSTimer * _Nonnull timer) {
        unlink("/tmp/MPWFileChangesStream_test.txt");
    }];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    INTEXPECT(result.count,1,@"atomically is 3 changes instead of 1");
    IDEXPECT([result.firstObject reference],@"/private/tmp/MPWFileChangesStream_test.txt",@"change");
    IDEXPECT([result.firstObject HTTPVerb],@"DELETE",@"change");
}

+(NSArray*)testSelectors
{
   return @[
			@"testGotAnEvent",
			];
}

@end
