//
//  MPWNotificationStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import "MPWEventWriter.h"
#import "NSObject+MPWNotificationProtocol.h"
#import "NSThreadInterThreadMessaging.h"

@interface MPWEventWriter ()

@property (nonatomic, strong) NSString *notificationName;
@property (nonatomic, assign) BOOL     shouldPostOnMainThread;

@end


@implementation MPWEventWriter

-(id)initWithNotificationName:(NSString *)name shouldPostOnMainThread:(BOOL)shouldPostOnMainThread
{
    self=[super init];
    self.notificationName=name;
    self.shouldPostOnMainThread=shouldPostOnMainThread;
    return self;
}

-(id)initWithNotificationProtocol:(Protocol *)protocol shouldPostOnMainThread:(BOOL)shouldPostOnMainThread
{
    return [self initWithNotificationName:@(protocol_getName(protocol)) shouldPostOnMainThread:shouldPostOnMainThread];
}

-(void)postNotificationObject:anObject
{
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName
                                                        object:anObject];
}

-(void)writeObject:anObject sender:sender
{
    if ( self.shouldPostOnMainThread) {
        [[self onMainThread] postNotificationObject:anObject];
    } else {
        [self postNotificationObject:anObject];
    }
}

-(void)dealloc
{
    [_notificationName release];
    [super dealloc];
}



@end

#import "DebugMacros.h"
#import "NSObject+MPWNotificationProtocol.h"

@protocol MPWNotificationStreamTesterProtocol<MPWNotificationProtocol>

-(void)hello:(NSNotification*)notification;

@end

@interface MPWNotificationStreamTester : NSObject<MPWNotificationStreamTesterProtocol>
@property (nonatomic,strong) id result;
@end

@implementation MPWEventWriter(testing)

+testFixture
{
    return [[[MPWNotificationStreamTester alloc] init] autorelease];
}

+testSelectors
{
    return @[
             @"testNotifyWhenSetupViaString",
             @"testNotifyWhenSetupViaProtocol",
             ];
}

@end



@implementation MPWNotificationStreamTester

-(void)hello:(NSNotification*)notification
{
    self.result = notification.object;
}


-(void)testNotifyWhenSetupViaString
{
    [self installProtocolNotifications];
    MPWEventWriter *s=[[[MPWEventWriter alloc] initWithNotificationName:@"MPWNotificationStreamTesterProtocol"  shouldPostOnMainThread:NO] autorelease];
    EXPECTNIL(self.result,@"nothing yet");
    [s writeObject:@"hello"];
    IDEXPECT(self.result,@"hello",@"notification was received");
}

-(void)testNotifyWhenSetupViaProtocol
{
    [self installProtocolNotifications];
    MPWEventWriter *s=[[[MPWEventWriter alloc] initWithNotificationProtocol:@protocol(MPWNotificationStreamTesterProtocol)  shouldPostOnMainThread:NO] autorelease];
    EXPECTNIL(self.result,@"nothing yet");
    [s writeObject:@"protocol"];
    IDEXPECT(self.result,@"protocol",@"notification was received");
}

-(void)dealloc
{
    [_result release];
    [super dealloc];
}


@end
