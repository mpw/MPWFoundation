//
//  MPWDistributedNotificationReceiver.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 08.03.21.
//

#import "MPWDistributedNotificationReceiver.h"

@implementation MPWDistributedNotificationReceiver

-(void)writeNotification:(NSNotification*)aNotification
{
    [self.target writeObject:aNotification.userInfo];
}

-(void)run
{
    [[NSClassFromString(@"NSDistributedNotificationCenter") defaultCenter] addObserver:self selector:@selector(writeNotification:) name:self.notificationName object:nil];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDistributedNotificationReceiver(testing) 


@end
