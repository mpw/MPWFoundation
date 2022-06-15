//
//  SSHConnection.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 15.06.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSHConnection : NSObject

@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;
@property (nonatomic,assign) int verbosity;

@end

NS_ASSUME_NONNULL_END
