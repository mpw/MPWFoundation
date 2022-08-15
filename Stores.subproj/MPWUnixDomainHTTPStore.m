//
//  MPWUnixDomainHTTPStore.m
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 27.07.22.
//

#import "MPWUnixDomainHTTPStore.h"
#include <sys/socket.h>
#include <sys/un.h>


@interface MPWUnixDomainHTTPStore()

@property (nonatomic, strong) NSString *socketPath;


@end

@implementation MPWUnixDomainHTTPStore

-(instancetype)initWithSocketPath:(NSString*)socketPath
{
    self=[super init];
    self.socketPath = socketPath;
    return self;
}



-at:ref
{
    int client_sock, rc;
    struct sockaddr_un server_sockaddr;
    char buf[16384];
    memset(&server_sockaddr, 0, sizeof(struct sockaddr_un));
    
    /**************************************/
    /* Create a UNIX domain stream socket */
    /**************************************/
    client_sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (client_sock == -1) {
        printf("SOCKET ERROR = %d\n", errno);
        exit(1);
    }

    server_sockaddr.sun_family = AF_UNIX;
    const char *spath=[self.socketPath UTF8String];
    
    strcpy(server_sockaddr.sun_path, spath);
    server_sockaddr.sun_len = strlen(spath)+1;
    rc = connect(client_sock, (struct sockaddr *) &server_sockaddr, sizeof server_sockaddr );
    if(rc == -1){
        printf("CONNECT ERROR = %d\n", errno);
        close(client_sock);
        return nil;
    }
    
    NSString *request = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\n\n\n",[ref path]];
    const char *request_str = [request UTF8String];

    rc = (int)write(client_sock, request_str, strlen(request_str)+1);
    if (rc == -1) {
        printf("SEND ERROR = %d\n", errno);
        close(client_sock);
    }
    
    memset(buf, 0, sizeof(buf));
    NSMutableData *result=[NSMutableData data];
    do {
        rc = (int)read(client_sock, buf, sizeof buf );
        if ( rc > 0) {
            [result appendBytes:buf length:rc];
        }
    } while ( rc > 0);
    NSData *body = nil;
    char *bytes=[result bytes];
    for (int i=0,max=result.length-3;i<max;i++) {
        if ( bytes[i]=='\r' && bytes[i+1]=='\n' && bytes[i+2]=='\r' && bytes[i+3]=='\n' ) {
            body=[result subdataWithRange:NSMakeRange(i+4,result.length-(i+5))];
//            NSLog(@"body at %d: '%@'",i,[body stringValue]);
            break;
        }
    }
    if (rc == -1) {
        printf("RECV ERROR = %d\n", errno);
    }

    /******************************/
    /* Close the socket and exit. */
    /******************************/
    close(client_sock);
    
    return body;
}


@end


@implementation MPWFileBinding(UnixSocket)

-asUnixSocketStore
{
    return [[[MPWUnixDomainHTTPStore alloc] initWithSocketPath:self.reference.path] autorelease];
}

@end
