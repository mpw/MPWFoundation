//
//  SSHCommandStream.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSHCommandStream : MPWStreamSource

-initWithSSHSession:(void*)session command:(NSString*)name;
-(void)run;


@end

NS_ASSUME_NONNULL_END
