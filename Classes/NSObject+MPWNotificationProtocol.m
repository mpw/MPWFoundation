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

static BOOL isNotificationProtocol( Protocol* aProtocol )
{
    return protocol_conformsToProtocol(aProtocol,@protocol(MPWNotificationProtocol));
}

NSString *notificatioNameFromProtocol(Protocol *aProtocol )
{
    return @(protocol_getName(aProtocol));
}

void sendProtocolNotification( Protocol *aProtocol, id anObject )
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notificatioNameFromProtocol(aProtocol) object:anObject];
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

-(void)handleNotificationProtocol:(Protocol*)aProtocol
{
    struct objc_method_description *protocolMethods=NULL;
    unsigned int count=0;
    protocolMethods=protocol_copyMethodDescriptionList(aProtocol,YES,YES,&count);
    if (protocolMethods && count==1) {
        SEL message=protocolMethods[0].name;
        NSLog(@"found message: %@ notification name: %@",NSStringFromSelector(message),notificatioNameFromProtocol(aProtocol));
        [self registerMessage:message forNotificationName:notificatioNameFromProtocol(aProtocol)];
    }
    free(protocolMethods);
}

-(void)installProtocolNotifications
{
    unsigned int protocolCount;
    Protocol** protocols=class_copyProtocolList([self class], &protocolCount);
    for (int i=0;i<protocolCount;i++ ) {
        if ( isNotificationProtocol( protocols[i]))  {
            NSLog(@"install protocol: %@",protocols[i]);
            [self handleNotificationProtocol:protocols[i]];
        }
    }
    free(protocols);
}


@end


@protocol MPWTestNotificationProtocol<MPWNotificationProtocol>

-(void)theTestNotificationMessage:(NSNotification*)notification;

@end

@interface MPWNotificationProtocolTests : NSObject<MPWTestNotificationProtocol>

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
    EXPECTTRUE( isNotificationProtocol(@protocol(MPWTestNotificationProtocol)), @"should be");
    EXPECTFALSE( isNotificationProtocol( @protocol(NSObject) ), @"should not be");

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
    [tester handleNotificationProtocol:@protocol(MPWTestNotificationProtocol)];
    [[NSNotificationCenter defaultCenter] postNotificationName:@(protocol_getName(@protocol(MPWTestNotificationProtocol))) object:nil];
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}

+(void)testSendProtocolNotification
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [tester handleNotificationProtocol:@protocol(MPWTestNotificationProtocol)];
    PROTOCOL_NOTIFY(MPWTestNotificationProtocol,nil);
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}

+(void)testInstallProtocolNotifications
{
    MPWNotificationProtocolTests* tester = [[self new] autorelease];
    EXPECTFALSE(tester.messageReceived, @"not yet");
    [tester installProtocolNotifications];
    PROTOCOL_NOTIFY(MPWTestNotificationProtocol,nil);
    EXPECTTRUE(tester.messageReceived, @"message received");
    
}


+testSelectors
{
    return @[
             @"testCanIdentifyProtocolIsANotificationProtocol",
             @"testInstallNotificationHandler",
             @"testRedirectNotificationToProtocolMessage",
             @"testSendProtocolNotification",
             @"testInstallProtocolNotifications",
             ];
}

@end
