//
//  MPWDistributedNotificationStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 08.03.21.
//

#import "MPWDistributedNotificationStream.h"



@implementation MPWDistributedNotificationStream


-(void)writeObject:anObject
{
    [[NSClassFromString(@"NSDistributedNotificationCenter") defaultCenter] postNotificationName: self.notificationName object:nil userInfo: anObject  deliverImmediately:1];
}


@end

