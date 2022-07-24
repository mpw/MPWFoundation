//
//  SSHCommandStore.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 24.07.22.
//

#import <MPWFoundation/MPWFoundation.h>

@class SSHConnection;

NS_ASSUME_NONNULL_BEGIN

@interface SSHCommandStore : MPWAbstractStore

-initWithConnection:sshConnection;

@end

NS_ASSUME_NONNULL_END
