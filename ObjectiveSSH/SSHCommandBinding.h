//
//  SSHCommandBinding.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 25.07.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SSHConnection;

@interface SSHCommandBinding : MPWStreamableReference

@property (nonatomic, strong)  SSHConnection *connection;

@end

NS_ASSUME_NONNULL_END
