//
//  SSHCommandStream.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import "SSHCommandStream.h"
#import "SSHConnection.h"
#import <libssh/libssh.h>

@interface SSHCommandStream()

@property (nonatomic, strong) NSString *command;
@property (nonatomic, weak) SSHConnection *connection;

@end

@implementation SSHCommandStream
{
    ssh_channel channel;
}

-initWithSSHConnection:(SSHConnection*)connection command:(NSString*)command
{
    self=[super init];
    self.command = command;
    self.connection = connection;
    if ( self ) {
        channel = ssh_channel_new([connection sshSession]);
        if ( !channel ) {
            NSLog(@"couldn't create channel from connection %p",connection);
            NSLog(@"couldn't create channel from connection %@",connection);
            NSLog(@"couldn't create channel from sesion %p: %s",[connection sshSession],ssh_get_error([connection sshSession]));
        }
    }
    return self;
}

//
//   For some reason ssh_channel_request_env() never seems to work
//
//-(void)sendEnvironmentVariables
//{
//    NSDictionary *env=self.env;
//    NSLog(@"env: %@",env);
//    for ( NSString *name in env) {
//        NSString *value=env[name];
//        if ( channel && name && value ) {
//            const char *n=[name UTF8String];
//            const char *v=[value UTF8String];
//            NSLog(@"will write '%s' %s' to channel %p",n,v,channel);
//            int rc = ssh_channel_request_env(channel,n,v);
//            NSLog(@"ssh_channel_request_env() rc=%d",rc);
//            if (rc <0 ) {
//                NSLog(@"error: %@",[self.connection sshError]);
//            }
//        }
//    }
//}

-(NSString*)commandsForEnvironmentVariables
{
    NSDictionary *env=self.env;
    NSMutableString *envCmd=[NSMutableString string];
    for ( NSString *name in env) {
        NSString *value=env[name];
        [envCmd appendFormat:@"export %@='%@'; ",name,value];
    }
    return envCmd;
}

-(void)run
{
    if ( channel ) {
        int rc;
//        [self sendEnvironmentVariables];
        rc = ssh_channel_open_session(channel);
        NSString *envCmd=[self commandsForEnvironmentVariables];
        NSString *totalCmd=[envCmd stringByAppendingString:self.command];
        rc = ssh_channel_request_exec(channel, [totalCmd UTF8String]);
//        NSLog(@"ssh_channel_request_exec() rc=%d",rc);
        char buffer[256];
        int nbytes=0;
        do {
            nbytes = ssh_channel_read(channel, buffer, sizeof(buffer), 0);
            if ( nbytes > 0 ) {
                [self.target writeObject:[NSData dataWithBytes:buffer length:nbytes]];
            }
        }  while (nbytes > 0);
        [self.target flush];
        ssh_channel_close(channel);
    } else {
        NSLog(@"no channel");
    }
}

-(NSData*)value
{
    SSHCommandStream *s=self;
    if ( !self.target){
        NSMutableData *result=[NSMutableData data];
        s.target = [MPWByteStream streamWithTarget:result];
    }
    [s run];
    return [s finalTarget];
}





@end
