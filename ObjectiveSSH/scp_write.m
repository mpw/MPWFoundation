/* libssh_scp.c
 */

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>

#include <libssh/libssh.h>
#include "examples_common.h"



@interface SCPWriter : NSObject
{
    struct ssh_session_struct *session;
    struct ssh_scp_struct *scp;
}
-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name;

@property (nonatomic,assign) int verbosity;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;


@end


@implementation SCPWriter

-(int)openSession
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

-(void)disconnect
{
    if ( session ) {
        ssh_disconnect(session);
        ssh_free(session);
        session = NULL;
    }
}

-(NSString*)sshError
{
    if ( session ) {
        return @(ssh_get_error(session));
    }
    return nil;
}

-(int)openDest:(NSString*)dest
{
    if (YES) {
        if ([self openSession]<0) {
            return -1;
        }
        
        scp = ssh_scp_new(session, SSH_SCP_WRITE, [dest UTF8String] );
        if (!scp) {
            NSLog(@"error: %@",[self sshError]);
            return -1;
        }
        
        if (ssh_scp_init(scp) == SSH_ERROR) {
            fprintf(stderr, "error : %s\n", ssh_get_error(session));
            ssh_scp_free(scp);
            scp = NULL;
            ssh_disconnect(session);
            ssh_free(session);
            session = NULL;
            return -1;
        }
        return 0;
    }
    return -1;
}


-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name
{
    size_t size=[data length];
    int w;
    size_t total = 0;
    mode_t mode=0644;
    const char *bytes=[data bytes];

    
    if ([self openDest:name] < 0) {
        printf("couldn't open dest\n");
        goto end;
    }
    
    
    
    int r = ssh_scp_push_file(scp, [name UTF8String], size, mode);
    //  snprintf(buffer, sizeof(buffer), "C0644 %d %s\n", size, src->path);
    if (r == SSH_ERROR) {
        fprintf(stderr,"error: %s\n",ssh_get_error(session));
        ssh_scp_free(scp);
        scp = NULL;
        return ;
    }
    
    do {
        const char *partToWrite = bytes + total;
        unsigned long r=MIN( 16384, [data length]-total);
        w = ssh_scp_write(scp, partToWrite, r);
        if (w == SSH_ERROR) {
            fprintf(stderr, "Error writing in scp: %s\n", ssh_get_error(session));
            ssh_scp_free(scp);
            scp = NULL;
            return;
        }
        total += r;
        
    } while(total < size);
    
    //    printf("wrote %zu bytes\n", total);
end:
    return ;
}


@end
