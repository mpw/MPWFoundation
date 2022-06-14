//
//  SSHCommandStream.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import "SSHCommandStream.h"
#import <libssh/libssh.h>

@interface SSHCommandStream()

@property (nonatomic, strong) NSString *command;

@end

@implementation SSHCommandStream
{
    ssh_channel channel;
}

-initWithSSHSession:(void*)session command:(NSString*)command
{
    self=[super init];
    self.command = command;
    if ( self ) {
        channel = ssh_channel_new(session);
        if ( !channel ) {
        }
    }
    return self;
}

-(void)run
{
    if ( channel ) {
        int rc;
        rc = ssh_channel_open_session(channel);
        NSLog(@"open channel: %d",rc);
        rc = ssh_channel_request_exec(channel, [self.command UTF8String]);
        NSLog(@"request exec: %d",rc);
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



@end
