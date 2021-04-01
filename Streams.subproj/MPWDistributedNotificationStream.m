//
//  MPWDistributedNotificationStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 08.03.21.
//

#import "MPWDistributedNotificationStream.h"



@implementation MPWDistributedNotificationStream

CONVENIENCEANDINIT(stream, WithProtocol:(Protocol*)aProtocol) {
    self=[super init];
    self.notificationName=@(protocol_getName(aProtocol));
    return self;
}

-(void)writeObject:anObject
{
    [(id)[NSClassFromString(@"NSDistributedNotificationCenter") defaultCenter] postNotificationName: self.notificationName object:nil userInfo: anObject  deliverImmediately:1];
}


@end

