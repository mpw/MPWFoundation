//
//  MPWDistributedNotificationStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 08.03.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWDistributedNotificationStream : MPWWriteStream

@property (nonatomic, strong)  NSString *notificationName;

@end

NS_ASSUME_NONNULL_END
