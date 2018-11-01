//
//  NSObject+MPWNotificationProtocol.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/17/18.
//  Copyright Marcel Weiher 2018
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface Protocol:NSObject {} @end

@protocol MPWNotificationProtocol
//  empty, this is a marker protocol, adopt this to signify that your protocol is a notification protocol
@end

@interface NSObject (MPWNotificationProtocol)

-(void)installProtocolNotifications;

@end

void sendProtocolNotification( Protocol *aProtocol, id anObject );
NSString *notificatioNameFromProtocol(Protocol *aProtocol );

@interface Protocol(notifications)

-(void)notify:anObject;
-(void)notify;
-(BOOL)isNotificationProtocol;

@end

