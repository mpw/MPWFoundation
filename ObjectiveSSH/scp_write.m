/* libssh_scp.c
 * Sample implementation of a SCP client
 */

/*
Copyright 2009 Aris Adamantiadis

This file is part of the SSH Library

You are free to copy this file, modify it in any way, consider it being public
domain. This does not apply to the rest of the library though, but it is
allowed to cut-and-paste working code from this file to any license of
program.
 */

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

#include <libssh/libssh.h>
#include "examples_common.h"

static char **sources;
static int nsources;
static char *destination;
static int verbosity = 0;

struct location {
    int is_ssh;
    char *user;
    char *host;
    char *path;
    ssh_session session;
    ssh_scp scp;
    FILE *file;
};

enum {
    READ,
    WRITE
};

static void usage(const char *argv0) {
    fprintf(stderr, "Usage : %s [options] [[user@]host1:]file1 ... \n"
            "                               [[user@]host2:]destination\n"
            "sample scp client - libssh-%s\n",
            //      "Options :\n",
            //      "  -r : use RSA to verify host public key\n",
            argv0,
            ssh_version(0));
    exit(0);
}

static int opts(int argc, char **argv) {
    int i;

    while((i = getopt(argc, argv, "v")) != -1) {
        switch(i) {
        case 'v':
            verbosity++;
            break;
        default:
            fprintf(stderr, "unknown option %c\n", optopt);
            usage(argv[0]);
            return -1;
        }
    }

    nsources = argc - optind;
    if (nsources < 1) {
        usage(argv[0]);
        return -1;
    }

    sources = malloc((nsources + 1) * sizeof(char *));
    if (sources == NULL) {
        return -1;
    }

    for(i = 0; i < nsources; ++i) {
        sources[i] = argv[optind];
        optind++;
    }

    sources[i] = NULL;
    return 0;
}

static void location_free(struct location *loc)
{
    if (loc) {
        if (loc->path) {
            free(loc->path);
        }
        loc->path = NULL;
        if (loc->is_ssh) {
            if (loc->host) {
                free(loc->host);
            }
            loc->host = NULL;
            if (loc->user) {
                free(loc->user);
            }
            loc->user = NULL;
            if (loc->host) {
                free(loc->host);
            }
            loc->host = NULL;
        }
        free(loc);
    }
}

static struct location *parse_location(char *loc) {
    struct location *location;
    char *ptr;

    location = malloc(sizeof(struct location));
    if (location == NULL) {
        return NULL;
    }
    memset(location, 0, sizeof(struct location));

    location->host = location->user = NULL;
    ptr = strchr(loc, ':');

    if (ptr != NULL) {
        location->is_ssh = 1;
        location->path = strdup(ptr+1);
        *ptr = '\0';
        ptr = strchr(loc, '@');

        if (ptr != NULL) {
            location->host = strdup(ptr+1);
            *ptr = '\0';
            location->user = strdup(loc);
        } else {
            location->host = strdup(loc);
        }
    } else {
        location->is_ssh = 0;
        location->path = strdup(loc);
    }
    return location;
}

static void close_location(struct location *loc) {
    int rc;

    if (loc) {
        if (loc->is_ssh) {
            if (loc->scp) {
                rc = ssh_scp_close(loc->scp);
                if (rc == SSH_ERROR) {
                    fprintf(stderr,
                            "Error closing scp: %s\n",
                            ssh_get_error(loc->session));
                }
                ssh_scp_free(loc->scp);
                loc->scp = NULL;
            }
            if (loc->session) {
                ssh_disconnect(loc->session);
                ssh_free(loc->session);
                loc->session = NULL;
            }
        } else {
            if (loc->file) {
                fclose(loc->file);
                loc->file = NULL;
            }
        }
    }
}





@interface SCPWriter : NSObject
{
    struct location dest;
}
-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name;

@property (nonatomic,assign) int verbosity;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;


@end


@implementation SCPWriter

-(int)openSession
{
    dest.session = connect_ssh(dest.host, dest.user, verbosity);
    if (dest.session) {
        fprintf(stderr, "Couldn't connect to %s\n", dest.host);
        return -1;
    }
    return 0;
}

-(int)openLocation
{
    struct location *loc=&dest;
    if (loc->is_ssh) {
        loc->session = connect_ssh(loc->host, loc->user, verbosity);
        if (!loc->session) {
            fprintf(stderr, "Couldn't connect to %s\n", loc->host);
            return -1;
        }
        
        loc->scp = ssh_scp_new(loc->session, SSH_SCP_WRITE, loc->path);
        if (!loc->scp) {
            fprintf(stderr, "error : %s\n", ssh_get_error(loc->session));
            ssh_disconnect(loc->session);
            ssh_free(loc->session);
            loc->session = NULL;
            return -1;
        }
        
        if (ssh_scp_init(loc->scp) == SSH_ERROR) {
            fprintf(stderr, "error : %s\n", ssh_get_error(loc->session));
            ssh_scp_free(loc->scp);
            loc->scp = NULL;
            ssh_disconnect(loc->session);
            ssh_free(loc->session);
            loc->session = NULL;
            return -1;
        }
        return 0;
    }
    return -1;
}


-(void)writeData:(NSData*)data toRemoteFile:(NSString*)name
{
    size_t size=[data length];
    int w, r;
    size_t total = 0;
    mode_t mode=0644;
    
    
    dest.is_ssh=1;
    dest.user=[self.user UTF8String];   // ubuntu
    dest.host=[self.host UTF8String];   //"130.61.236.203";
    dest.path=[name UTF8String];
    
    
    
    if ([self openLocation] < 0) {
        r = EXIT_FAILURE;
        printf("couldn't open dest\n");
        goto end;
    }
    

    
    if (dest.is_ssh) {
        r = ssh_scp_push_file(dest.scp, dest.path, size, mode);
        //  snprintf(buffer, sizeof(buffer), "C0644 %d %s\n", size, src->path);
        if (r == SSH_ERROR) {
            fprintf(stderr,"error: %s\n",ssh_get_error(dest.session));
            ssh_scp_free(dest.scp);
            dest.scp = NULL;
            return ;
        }
    }
    
    char *bytes=[data bytes];
    do {
        char *partToWrite = bytes + total;
        int r=MIN( 16384, [data length]-total);
        w = ssh_scp_write(dest.scp, partToWrite, r);
        if (w == SSH_ERROR) {
            fprintf(stderr, "Error writing in scp: %s\n", ssh_get_error(dest.session));
            ssh_scp_free(dest.scp);
            dest.scp = NULL;
            return;
        }
       total += r;
        
    } while(total < size);
    
    //    printf("wrote %zu bytes\n", total);
end:
    return ;
}


@end
