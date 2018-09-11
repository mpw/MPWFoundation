//
//  MPWNotificationStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWNotificationStream : MPWWriteStream

-(id)initWithNotificationName:(NSString *)name shouldPostOnMainThread:(BOOL)shouldPostOnMainThread;

@end
