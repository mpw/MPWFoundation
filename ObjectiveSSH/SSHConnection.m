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


-(ssh_session)connect {
    ssh_session localSsession;
    int auth=0;
    
    localSsession=ssh_new();
    if (localSsession == NULL) {
        return NULL;
    }
    
    if(self.user != NULL){
        if (ssh_options_set(localSsession, SSH_OPTIONS_USER, [self.user UTF8String]) < 0) {
            ssh_free(localSsession);
            return NULL;
        }
    }

    if(self.port != 0 && self.port != 22){
        int localPort=self.port;
        if (ssh_options_set(localSsession, SSH_OPTIONS_PORT, &localPort ) < 0) {
            ssh_free(localSsession);
            return NULL;
        }
    }

    if (ssh_options_set(localSsession, SSH_OPTIONS_HOST, [self.host UTF8String]) < 0) {
        ssh_free(localSsession);
        return NULL;
    }
    int localVerbosity=self.verbosity;
    ssh_options_set(localSsession, SSH_OPTIONS_LOG_VERBOSITY, &localVerbosity);
    ssh_key privkey=NULL;
    if ( self.identityKeyPath) {
        int rc = ssh_pki_import_privkey_file([self.identityKeyPath UTF8String], NULL, NULL, NULL, &privkey);
        if (rc != SSH_OK) {
            fprintf(stderr, "Key load failed\n");
            privkey=NULL;
        }
    }
    
    
    if(ssh_connect(localSsession)){
        fprintf(stderr,"Connection failed : %s\n",ssh_get_error(localSsession));
        ssh_disconnect(localSsession);
        ssh_free(localSsession);
        return NULL;
    }
//    if(verify_knownhost(localSsession)<0){
//        ssh_disconnect(localSsession);
//        ssh_free(localSsession);
//        return NULL;
//    }
    auth=-1;
    if ( privkey ) {
        auth=ssh_userauth_publickey(localSsession, NULL, privkey);
        if ( auth != SSH_AUTH_SUCCESS) {
            fprintf(stderr,"auth with privkey %p failed: %d, continuing\n",privkey,auth);
        }
    }
    if (auth != SSH_AUTH_SUCCESS && self.password )  {
        auth=ssh_userauth_password(localSsession, NULL, [self.password UTF8String]);
    }
   if (auth != SSH_AUTH_SUCCESS)  {
        auth=authenticate_console(localSsession);
    }
    if(auth==SSH_AUTH_SUCCESS){
        return localSsession;
    } else if(auth==SSH_AUTH_DENIED){
        fprintf(stderr,"Authentication failed (DENIED)\n");
    } else {
        fprintf(stderr,"Error while authenticatin %d\n",auth);
    }
    ssh_disconnect(localSsession);
    ssh_free(localSsession);
    return NULL;
}


-(int)openSSH
{
    if ( !session ) {
        session = [self connect];
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
