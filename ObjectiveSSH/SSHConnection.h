//
//  SSHConnection.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 15.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SFTPStore,SSHCommandStream;

@interface SSHConnection : NSObject <SSHConnection>

@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *identityKeyPath;
@property (nonatomic, assign) int port;
@property (nonatomic,assign) int verbosity;
@property (nonatomic, strong) NSDictionary *env;

-(SFTPStore*)store;
-(SSHCommandStream*)command:(NSString*)command outputTo:(NSObject <Streaming>*)output;
-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output;
-(NSData*)run:(NSString*)command;
-(void*)sshSession;
-(NSString*)sshError;


@end

NS_ASSUME_NONNULL_END
