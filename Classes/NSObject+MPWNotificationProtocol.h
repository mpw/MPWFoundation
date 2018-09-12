//
//  NSObject+MPWNotificationProtocol.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/17/18.
//  Copyright Marcel Weiher 2018
//

#import <Foundation/Foundation.h>

@protocol MPWNotificationProtocol
//  empty, this is a marker protocol
@end

@interface NSObject (MPWNotificationProtocol)

-(void)installProtocolNotifications;

@end

void sendProtocolNotification( Protocol *aProtocol, id anObject );
NSString *notificatioNameFromProtocol(Protocol *aProtocol );


#define PROTOCOL_NOTIFY(protocolName, object)   sendProtocolNotification(@protocol(protocolName),object )
