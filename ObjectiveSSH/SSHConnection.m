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


static ssh_session connect_ssh_local(const char *host, const char *user,int verbosity, int port ){
    ssh_session session;
    int auth=0;
    
    session=ssh_new();
    if (session == NULL) {
        return NULL;
    }
    
    if(user != NULL){
        if (ssh_options_set(session, SSH_OPTIONS_USER, user) < 0) {
            ssh_free(session);
            return NULL;
        }
    }

    if(port != 0 && port != 22){
        if (ssh_options_set(session, SSH_OPTIONS_PORT, &port ) < 0) {
            ssh_free(session);
            return NULL;
        }
    }

    if (ssh_options_set(session, SSH_OPTIONS_HOST, host) < 0) {
        ssh_free(session);
        return NULL;
    }
    ssh_options_set(session, SSH_OPTIONS_LOG_VERBOSITY, &verbosity);
    if(ssh_connect(session)){
        fprintf(stderr,"Connection failed : %s\n",ssh_get_error(session));
        ssh_disconnect(session);
        ssh_free(session);
        return NULL;
    }
    if(verify_knownhost(session)<0){
        ssh_disconnect(session);
        ssh_free(session);
        return NULL;
    }
    auth=authenticate_console(session);
    if(auth==SSH_AUTH_SUCCESS){
        return session;
    } else if(auth==SSH_AUTH_DENIED){
        fprintf(stderr,"Authentication failed\n");
    } else {
        fprintf(stderr,"Error while authenticating : %s\n",ssh_get_error(session));
    }
    ssh_disconnect(session);
    ssh_free(session);
    return NULL;
}


-(int)openSSH
{
    if ( !session ) {
        session = connect_ssh_local([[self host] UTF8String], [[self user] UTF8String], self.verbosity, self.port );
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
