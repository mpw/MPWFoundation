/* libssh_scp.c
 */

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>

#include <libssh/libssh.h>
#include <libssh/sftp.h>

#include "examples_common.h"



@interface SCPWriter : NSObject
{
    struct ssh_session_struct *session;
    sftp_session sftp;
    struct ssh_scp_struct *scp;
}
-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name;

@property (nonatomic,assign) int verbosity;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;


@end


@implementation SCPWriter

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

-(int)openSFTP
{
    if ( !sftp ) {
        [self openSSH];
        if ( session )  {
            sftp=sftp_new(session);
            if (sftp) {
                sftp_init(sftp);
            } else {
                sftp_free(sftp);
                return -1;
            }
        }
    }
    return sftp ? 0 : -1;
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



-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name
{
    size_t size=[data length];
    size_t total = 0;
    const char *bytes=[data bytes];
    int access_type = O_WRONLY | O_CREAT | O_TRUNC;
    sftp_file file;

    
    if ([self openSFTP] < 0) {
        printf("couldn't open dest\n");
        goto end;
    }
    
    
    file = sftp_open(sftp, [name UTF8String], access_type, S_IRWXU);
    if ( file ) {
        do {
            const char *partToWrite = bytes + total;
            size_t numBytesToWrite=(int)MIN( 16384, [data length]-total);
            size_t written = sftp_write(file, partToWrite, numBytesToWrite);
            if (written == SSH_ERROR) {
                fprintf(stderr, "Error writing in scp: %s\n", ssh_get_error(session));
                ssh_scp_free(scp);
                scp = NULL;
                return;
            }
            total += written;
            
        } while(total < size);
        sftp_close(file);
    } else {
        NSLog(@"error opening sftp file connection: %@",[self sshError]);
    }
    
    //    printf("wrote %zu bytes\n", total);
end:
    return ;
}


@end
