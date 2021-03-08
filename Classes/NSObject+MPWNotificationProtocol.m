//
//  NSObject+MPWNotificationProtocol.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/17/18.
//  Copyright Marcel Weiher 2018
//

#import "NSObject+MPWNotificationProtocol.h"
#import "DebugMacros.h"

//#import <objc/runtime.h>

#if !TARGET_OS_IPHONE
@interface NSObject(notificationInstallation)

-(void)installAsNotificationHandler:aHandler;

@end
#endif


NSString *notificatioNameFromProtocol(Protocol *aProtocol )
{
    return @(protocol_getName(aProtocol));
}

static BOOL isNotificationProtocol(Protocol *aProtocol ) {
    return protocol_conformsToProtocol(aProtocol,@protocol(MPWNotificationProtocol));
}

static BOOL isDistributedNotificationProtocol(Protocol *aProtocol ) {
    return protocol_conformsToProtocol(aProtocol,@protocol(MPWDistributedNotificationProtocol));
}


void sendProtocolNotification( Protocol *aProtocol, id anObject )
{
    if ( isNotificationProtocol( aProtocol) ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:notificatioNameFromProtocol(aProtocol) object:anObject];

    } else {
        [NSException raise:@"invalidprotocol" format:@"Trying to notify via protocol '%s' that's not a notification protocol",protocol_getName(aProtocol)];
    }
}

static void installNotificationProtocol( Protocol *self , id aHandler)
{
    if ( isNotificationProtocol( self ) ) {
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
static void installDistributedNotificationProtocol( Protocol *self , id aHandler)
{
    if ( isDistributedNotificationProtocol( self ) ) {
        struct objc_method_description *protocolMethods=NULL;
        unsigned int count=0;
        protocolMethods=protocol_copyMethodDescriptionList(self,YES,YES,&count);
        if (protocolMethods && count==1) {
            SEL message=protocolMethods[0].name;
            [aHandler registerMessage:message forDistributedNotificationName:notificatioNameFromProtocol(self)];
        } else {
            [NSException raise:@"invalidprotocol" format:@"Notification protocol '%s' needs to have exactly 1 message defined, has %d",protocol_getName(self),count];
        }
        free(protocolMethods);
    } else {
        [NSException raise:@"invalidprotocol" format:@"Trying to install notification handler for protocol '%s' that's not a notification protocol",protocol_getName(self)];
    }
}




@implementation NSObject(MPWNotificationProtocol)

-(void)registerMessage:(SEL)aMessage forNotificationName:(NSString*)notificationName
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:aMessage name:notificationName object:nil];
}

-(void)registerMessage:(SEL)aMessage forDistributedNotificationName:(NSString*)notificationName
{
    [[NSClassFromString(@"NSDistributedNotificationCenter") defaultCenter] addObserver:self selector:aMessage name:notificationName object:nil];
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
        if (  isNotificationProtocol( protocols[i] )) {
            installNotificationProtocol(protocols[i], self);
        }
        if (  isDistributedNotificationProtocol( protocols[i] )) {
            installDistributedNotificationProtocol(protocols[i], self);
        }
    }
    free(protocols);
}

@end



#if !TARGET_OS_IPHONE
@implementation NSObject(notifications)

-(BOOL)isNotificationProtocol
{
    return isNotificationProtocol( (Protocol*)self );
}

-(void)notify:anObject
{
    sendProtocolNotification((Protocol*)self, anObject);

}

-(void)notify
{
    [self notify:nil];
}

@end


@implementation NSObject(notificationInstallation)


-(void)installAsNotificationHandler:aHandler
{
    if ( [self isNotificationProtocol]) {
        struct objc_method_description *protocolMethods=NULL;
        unsigned int count=0;
        protocolMethods=protocol_copyMethodDescriptionList((Protocol*)self,YES,YES,&count);
        if (protocolMethods && count==1) {
            SEL message=protocolMethods[0].name;
            [aHandler registerMessage:message forNotificationName:notificatioNameFromProtocol((Protocol*)self)];
        } else {
            [NSException raise:@"invalidprotocol" format:@"Notification protocol '%s' needs to have exactly 1 message defined, has %d",protocol_getName((Protocol*)self),count];
        }
        free(protocolMethods);
    } else {
        [NSException raise:@"invalidprotocol" format:@"Trying to install notification handler for protocol '%s' that's not a notification protocol",protocol_getName((Protocol*)self)];
    }
}

@end
#endif

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

@end

@implementation MPWNotificationProtocolTests

-(void)theTestNotificationMessage:(NSNotification*)notification
{
    self.messageReceived=YES;
}

+(void)testCanIdentifyProtocolIsANotificationProtocol
{
    isNotificationProtocol( @protocol(MPWTestNotificationProtocol));

    EXPECTTRUE(isNotificationProtocol( @protocol(MPWTestNotificationProtocol)), @"should be");
    EXPECTFALSE( isNotificationProtocol( @protocol(NSObject) ), @"should not be");

}
#if !TARGET_OS_IPHONE
+(void)testCanIdentifyProtocolIsANotificationProtocolMessages
{
    EXPECTTRUE( [@protocol(MPWTestNotificationProtocol) isNotificationProtocol], @"should be");
    EXPECTFALSE( [@protocol(NSObject) isNotificationProtocol], @"should not be");

}

+(void)testSendNotificationViaMessageToProtocol
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [tester installProtocolNotifications];
    [@protocol(MPWTestNotificationProtocol) notify];
    EXPECTTRUE(tester.messageReceived, @"message received");

}
#endif

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
    installNotificationProtocol( @protocol(MPWTestNotificationProtocol) , tester);
//    [@protocol(MPWTestNotificationProtocol) installAsNotificationHandler:tester];
    [[NSNotificationCenter defaultCenter] postNotificationName:@(protocol_getName(@protocol(MPWTestNotificationProtocol))) object:nil];
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}

+(void)testSendProtocolNotification
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    installNotificationProtocol( @protocol(MPWTestNotificationProtocol) , tester);
    sendProtocolNotification( @protocol(MPWTestNotificationProtocol), nil);
    EXPECTTRUE(tester.messageReceived, @"message received");

}

+(void)testSendProtocolNotificationViaProtocol
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    installNotificationProtocol( @protocol(MPWTestNotificationProtocol) , tester);
    sendProtocolNotification( @protocol(MPWTestNotificationProtocol), nil);
    EXPECTTRUE(tester.messageReceived, @"message received");

}

+(void)testTryingToNotifyViaNonNotificationProtocolRaises
{
    BOOL didRaise=NO;
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    installNotificationProtocol(@protocol(MPWTestNotificationProtocol), tester);
    @try {
        sendProtocolNotification(@protocol(NSObject), nil);
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
        installNotificationProtocol(@protocol(NSObject), tester);
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
        installNotificationProtocol(@protocol(InvalidMPWTestNotificationProtocolWithNoMessages), tester);
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
        installNotificationProtocol(@protocol(InvalidMPWTestNotificationProtocolWithTwoMessages), tester);
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
    sendProtocolNotification( @protocol(MPWTestNotificationProtocol), nil);
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
#if !TARGET_OS_IPHONE
             @"testCanIdentifyProtocolIsANotificationProtocolMessages",
             @"testSendNotificationViaMessageToProtocol",
#endif
             ];
}

@end
