// SFTPStore.m
//
// Copyright 2022 Marcel Weiher
//


#import "SFTPStore.h"


#include <libssh/libssh.h>
#include <libssh/sftp.h>

#include "examples_common.h"





@implementation SCPWriter
{
    struct ssh_session_struct *session;
    sftp_session sftp;
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

#define BUFFER_SIZE 16384

-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name
{
    data = [data asData];
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
            size_t numBytesToWrite=(int)MIN( BUFFER_SIZE, [data length]-total);
            size_t written = sftp_write(file, partToWrite, numBytesToWrite);
            if (written == SSH_ERROR) {
                fprintf(stderr, "Error writing in scp: %s\n", ssh_get_error(session));
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

-(NSData*)readDataAtPath:(NSString*)name
{
    int access_type = O_RDONLY;
    sftp_file file;
    NSMutableData *result=nil;

    if ([self openSFTP] < 0) {
        printf("couldn't open dest\n");
        goto end;
    }
    
    
    file = sftp_open(sftp, [name UTF8String], access_type, S_IRWXU);
    if ( file ) {
        result=[NSMutableData data];
        char *buffer[BUFFER_SIZE];
        size_t numBytesRead=0;
        do {
            numBytesRead = sftp_read(file, buffer, BUFFER_SIZE);
            if (numBytesRead == SSH_ERROR) {
                fprintf(stderr, "Error reading in sftp: %s\n", ssh_get_error(session));
                sftp_close(file);
                return result;
            }
            [result appendBytes:buffer length:numBytesRead];
        } while(numBytesRead >= BUFFER_SIZE);
        sftp_close(file);
    } else {
        NSLog(@"error opening sftp file connection: %@",[self sshError]);
    }
    
    //    printf("wrote %zu bytes\n", total);
end:
    return result;
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    if ( theObject ) {
        [self writeData:[theObject asData] toRemoteFile:[aReference path]];
    } else {
        [self mkdir:aReference];
    }
}

-(id)at:(id<MPWReferencing>)aReference
{
    return [self readDataAtPath:[aReference path]];
}

-(void)mkdir:(id<MPWReferencing>)aReference
{
    if ([self openSFTP] >= 0) {
        sftp_mkdir(sftp, [[aReference path] UTF8String], 0644);
    }
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    if ([self openSFTP] >= 0) {
        const char *path = [[aReference path] UTF8String];
        if ( path ) {
            sftp_attributes attrs = sftp_stat(sftp, path );
            int errcode=0;
            if ( attrs && attrs->type == SSH_FILEXFER_TYPE_DIRECTORY) {
                errcode = sftp_rmdir(sftp, path);
            } else {
                errcode = sftp_unlink(sftp, path);
            }
            if (errcode < 0 ) {
                NSLog(@"Error deleting: %@",[self sshError]);
            }
        }
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
