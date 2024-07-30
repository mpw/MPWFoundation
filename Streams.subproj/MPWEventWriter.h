//
//  MPWNotificationStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import <MPWFoundation/MPWWriteStream.h>

@interface MPWEventWriter : MPWWriteStream

-(id)initWithNotificationName:(NSString *)name shouldPostOnMainThread:(BOOL)shouldPostOnMainThread;
-(id)initWithNotificationProtocol:(Protocol *)protocol shouldPostOnMainThread:(BOOL)shouldPostOnMainThread;

@end
