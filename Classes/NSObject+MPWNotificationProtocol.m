//
//  NSObject+MPWNotificationProtocol.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/17/18.
//  Copyright Marcel Weiher 2018
//

#import "NSObject+MPWNotificationProtocol.h"
#import "DebugMacros.h"
#import <objc/runtime.h>

@interface Protocol(notificationInstallation)

-(void)installAsNotificationHandler:aHandler;

@end



void sendProtocolNotification( Protocol *aProtocol, id anObject )
{
    [aProtocol notify:anObject];
}


@implementation NSObject (MPWNotificationProtocol)

-(void)registerMessage:(SEL)aMessage forNotificationName:(NSString*)notificationName
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:aMessage name:notificationName object:nil];
}

-(void)registerNotificationMessage:(SEL)aMessage
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:aMessage name:NSStringFromSelector(aMessage) object:nil];
}

-(void)installProtocolNotifications
{
    unsigned int protocolCount=0;
    Protocol** protocols=class_copyProtocolList([self class], &protocolCount);
    for (int i=0;i<protocolCount;i++ ) {
        if ( [protocols[i]  isNotificationProtocol]) {
            [protocols[i] installAsNotificationHandler:self];
        }
    }
    free(protocols);
}



@end

@implementation Protocol(notifications)

-(BOOL)isNotificationProtocol
{
    return protocol_conformsToProtocol(self,@protocol(MPWNotificationProtocol));
}

-(void)notify:anObject
{
    if ( [self isNotificationProtocol]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificatioNameFromProtocol(self) object:anObject];

    } else {
        [NSException raise:@"invalidprotocol" format:@"Trying to notify via protocol '%s' that's not a notification protocol",protocol_getName(self)];
    }
}

-(void)notify
{
    [self notify:nil];
}

@end

@implementation Protocol(notificationInstallation)

NSString *notificatioNameFromProtocol(Protocol *aProtocol )
{
    return @(protocol_getName(aProtocol));
}


-(void)installAsNotificationHandler:aHandler
{
    if ( [self isNotificationProtocol]) {
        struct objc_method_description *protocolMethods=NULL;
        unsigned int count=0;
        protocolMethods=protocol_copyMethodDescriptionList(self,YES,YES,&count);
        if (protocolMethods && count==1) {
            SEL message=protocolMethods[0].name;
            [aHandler registerMessage:message forNotificationName:notificatioNameFromProtocol(self)];
        } else {
            [NSException raise:@"invalidprotocol" format:@"Notification protocol '%s' needs to have exactly 1 message defined, has %d",protocol_getName(self),count];
        }
        free(protocolMethods);
    } else {
        [NSException raise:@"invalidprotocol" format:@"Trying to install notification handler for protocol '%s' that's not a notification protocol",protocol_getName(self)];
    }
}


@end

@protocol MPWTestNotificationProtocol<MPWNotificationProtocol>

-(void)theTestNotificationMessage:(NSNotification*)notification;

@end

@protocol InvalidMPWTestNotificationProtocolWithNoMessages<MPWNotificationProtocol>

@end

@protocol InvalidMPWTestNotificationProtocolWithTwoMessages<MPWNotificationProtocol>
-(void)theTestNotificationMessage1:(NSNotification*)notification;
-(void)theTestNotificationMessage2:(NSNotification*)notification;


@end


@interface MPWNotificationProtocolTests : NSObject<MPWTestNotificationProtocol,NSObject>

@property BOOL messageReceived;
-(void)theTestNotificationMessage:(NSNotification*)notification;
@end

@implementation MPWNotificationProtocolTests

-(void)theTestNotificationMessage:(NSNotification*)notification
{
    self.messageReceived=YES;
}

+(void)testCanIdentifyProtocolIsANotificationProtocol
{
    EXPECTTRUE( [@protocol(MPWTestNotificationProtocol) isNotificationProtocol], @"should be");
    EXPECTFALSE( [@protocol(NSObject) isNotificationProtocol], @"should not be");

}

+(void)testInstallNotificationHandler
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [tester registerMessage:@selector(theTestNotificationMessage:) forNotificationName:@"hi"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hi" object:nil];
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}

+(void)testRedirectNotificationToProtocolMessage
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [@protocol(MPWTestNotificationProtocol) installAsNotificationHandler:tester];
    [[NSNotificationCenter defaultCenter] postNotificationName:@(protocol_getName(@protocol(MPWTestNotificationProtocol))) object:nil];
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}

+(void)testSendProtocolNotification
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [@protocol(MPWTestNotificationProtocol) installAsNotificationHandler:tester];
    [@protocol(MPWTestNotificationProtocol) notify];
    EXPECTTRUE(tester.messageReceived, @"message received");

}

+(void)testSendProtocolNotificationViaProtocol
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [@protocol(MPWTestNotificationProtocol) installAsNotificationHandler:tester];
    [@protocol(MPWTestNotificationProtocol) notify];
    EXPECTTRUE(tester.messageReceived, @"message received");

}

+(void)testTryingToNotifyViaNonNotificationProtocolRaises
{
    BOOL didRaise=NO;
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [@protocol(MPWTestNotificationProtocol) installAsNotificationHandler:tester];
    @try {
        [@protocol(NSObject) notify];
        EXPECTTRUE(false,@"should have raised");
    } @catch (id exception) {
        didRaise=YES;
    }
    EXPECTTRUE(didRaise, @"did raise");
    EXPECTFALSE(tester.messageReceived, @"message received");

}

+(void)testTryingToInstallNonNotificationProtocolRaises
{
    NSString *exceptionMessage=nil;
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    @try {
        [@protocol(NSObject) installAsNotificationHandler:tester];
    } @catch (NSException* exception) {
        exceptionMessage=exception.description;
    }
    IDEXPECT(exceptionMessage, @"Trying to install notification handler for protocol 'NSObject' that's not a notification protocol", @"the exception");
}

+(void)testTryingToInstallNotificationProtocolWithoutMessagesRaises
{
    NSString *exceptionMessage=nil;
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    @try {
        [@protocol(InvalidMPWTestNotificationProtocolWithNoMessages) installAsNotificationHandler:tester];
    } @catch (NSException* exception) {
        exceptionMessage=exception.description;
    }
    IDEXPECT(exceptionMessage, @"Notification protocol 'InvalidMPWTestNotificationProtocolWithNoMessages' needs to have exactly 1 message defined, has 0", @"the exception");
}

+(void)testTryingToInstallNotificationProtocolWithTooManyMessagesRaises
{
    NSString *exceptionMessage=nil;
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    @try {
        [@protocol(InvalidMPWTestNotificationProtocolWithTwoMessages) installAsNotificationHandler:tester];
    } @catch (NSException* exception) {
        exceptionMessage=exception.description;
    }
    IDEXPECT(exceptionMessage, @"Notification protocol 'InvalidMPWTestNotificationProtocolWithTwoMessages' needs to have exactly 1 message defined, has 2", @"the exception");
}


+(void)testInstallProtocolNotifications
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [tester installProtocolNotifications];
    [@protocol(MPWTestNotificationProtocol) notify];
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}


+testSelectors
{
    return @[
             @"testCanIdentifyProtocolIsANotificationProtocol",
             @"testInstallNotificationHandler",
             @"testRedirectNotificationToProtocolMessage",
             @"testSendProtocolNotification",
             @"testSendProtocolNotificationViaProtocol",
             @"testInstallProtocolNotifications",
             @"testTryingToNotifyViaNonNotificationProtocolRaises",
             @"testTryingToInstallNonNotificationProtocolRaises",
             @"testTryingToInstallNotificationProtocolWithoutMessagesRaises",
             @"testTryingToInstallNotificationProtocolWithTooManyMessagesRaises",
             ];
}

@end
