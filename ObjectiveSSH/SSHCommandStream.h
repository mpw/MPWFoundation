//
//  SSHCommandStream.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

@class SSHConnection;

NS_ASSUME_NONNULL_BEGIN

@interface SSHCommandStream : MPWStreamSource

@property (nonatomic, strong) NSDictionary *env;


-initWithSSHConnection:(SSHConnection*)session command:(NSString*)name;
-(void)run;


@end

NS_ASSUME_NONNULL_END
