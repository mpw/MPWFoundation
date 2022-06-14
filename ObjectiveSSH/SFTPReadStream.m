//
//  SFTPReadStream.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import "SFTPReadStream.h"
#import <libssh/sftp.h>

@implementation SFTPReadStream
{
    sftp_file file;
}

-initWithSFTPSession:(void*)sftp_session name:(NSString*)name
{
    self=[super init];
    if ( self ) {
        file = sftp_open(sftp_session, [name UTF8String], O_RDONLY, 0 );
    }
    return self;
}

#define BUFFER_SIZE 16384

-(void)run
{
    @autoreleasepool {
        if ( file ) {
            size_t numBytesRead=0;
            do {
                @autoreleasepool {
                    char *buffer[BUFFER_SIZE];
                    numBytesRead = sftp_read(file, buffer, BUFFER_SIZE);
                    if (numBytesRead == SSH_ERROR) {
                        NSLog(@"got an error");
                        sftp_close(file);
                        return ;
                    }
                    [self.target writeObject:[NSData dataWithBytes:buffer length:numBytesRead]];
                }
            } while(numBytesRead >= BUFFER_SIZE);
            [self.target flush];
            sftp_close(file);
        } else {
            NSLog(@"file not open");
        }
    }
}


@end
