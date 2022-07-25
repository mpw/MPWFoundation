//
//  SSHConnection.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 15.06.22.
//

#import "SSHConnection.h"
#import "SFTPStore.h"
#import "SSHCommandStream.h"
#import "SSHCommandStore.h"

#include <libssh/libssh.h>
#include "examples_common.h"


@implementation SSHConnection
{
    ssh_session session;
}

-(int)openSSH
{
    if ( !session ) {
        session = connect_ssh([[self host] UTF8String], [[self user] UTF8String], self.verbosity);
        if (!session) {
            fprintf(stderr, "Couldn't connect to %s\n", [[self host] UTF8String]);
            return -1;
        }
    }
    return 0;
}

-(void*)sshSession
{
    return session;
}

-(NSString*)sshError
{
    if ( session ) {
        return @(ssh_get_error(session));
    }
    return nil;
}



-(SFTPStore*)store
{
    [self openSSH];
    return [[[SFTPStore alloc] initWithSession:self] autorelease];
}

-(SSHCommandStore*)commandStore
{
    [self openSSH];
    return [[[SSHCommandStore alloc] initWithConnection:self] autorelease];
}

-(SSHCommandStream*)command:(NSString*)command outputTo:(NSObject <Streaming>*)output
{
    [self openSSH];
    SSHCommandStream *s = [[[SSHCommandStream alloc] initWithSSHConnection:self command:command] autorelease];
    s.env = self.env;
    s.target = output;
    return s;
}

-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output
{
    SSHCommandStream *c=[self command:command outputTo:output];
    [c run];
}

-(NSData*)run:(NSString*)command
{
    NSMutableData *result=[NSMutableData data];
    [self run:command outputTo:[MPWByteStream streamWithTarget:result]];
    return result;
}

-(void)disconnect
{
    if ( session ) {
        ssh_disconnect(session);
//        ssh_free(session);
        session = NULL;
    }
}


-(void)dealloc
{
    [self disconnect];
    [_host release];
    [_user release];
    [super dealloc];
}

@end
