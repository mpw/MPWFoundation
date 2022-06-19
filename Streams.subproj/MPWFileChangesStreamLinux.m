//
//  MPWFileChangesStreamLinux.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 17.06.22.
//

#import "MPWFileChangesStream.h"
#import "MPWRESTOperation.h"

#include <sys/inotify.h>
//#include <limits.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <unistd.h>

@implementation MPWFileChangesStream
{
    int inotifyFd;
}

-(instancetype)initWithDirectoryPath:(NSString*)aPath
{
    self=[super init];
    [self start];
    [self addPath:aPath];
    return self;
}

-(void)start
{
    inotifyFd = inotify_init();         /* Create inotify instance */
}

-(void)addPath:(NSString*)path
{
    inotify_add_watch(inotifyFd, [path UTF8String], IN_ALL_EVENTS);
}

#define BUF_LEN (10 * (sizeof(struct inotify_event) + NAME_MAX + 1))

-(void)readFromStream
{
    char buf[BUF_LEN] __attribute__ ((aligned(8)));
    ssize_t numRead;
    char *p;
    struct inotify_event *event;

    for (;;) {                          /* Read events forever */
        numRead = read(inotifyFd, buf, BUF_LEN);
        if (numRead <= 0) {
            fprintf(stderr, "read() from inotify fd returned <= 0!");
            exit(EXIT_FAILURE);
        }
                
        /* Process all of the events in buffer returned by read() */
        
        for (p = buf; p < buf + numRead; ) {
            event = (struct inotify_event *) p;
            [self writeInotifyEvent:event];
            
            p += sizeof(struct inotify_event) + event->len;
        }
    }
}
-(void)run
{
    [self readFromStream];
}

-(void)writeInotifyEvent:(struct inotify_event *)i
{
    @autoreleasepool {
        MPWRESTVerb verb = MPWRESTVerbInvalid;
        NSString *path=[NSString stringWithUTF8String:i->name];
        if ( i->mask & IN_MODIFY ) {
            verb=MPWRESTVerbPUT;
        } else if  ( i->mask & IN_DELETE ) {
            verb=MPWRESTVerbDELETE;
        }
        if (verb !=  MPWRESTVerbInvalid) {
            MPWRESTOperation *op=[MPWRESTOperation operationWithReference:path verb:verb];
            [self.target writeObject:op];
        }
    }

//    printf("    wd =%2d; ", i->wd);
//    if (i->cookie > 0)
//        printf("cookie =%4d; ", i->cookie);
//
//    printf("mask = ");
//    if (i->mask & IN_ACCESS)        printf("IN_ACCESS ");
//    if (i->mask & IN_ATTRIB)        printf("IN_ATTRIB ");
//    if (i->mask & IN_CLOSE_NOWRITE) printf("IN_CLOSE_NOWRITE ");
//    if (i->mask & IN_CLOSE_WRITE)   printf("IN_CLOSE_WRITE ");
//    if (i->mask & IN_CREATE)        printf("IN_CREATE ");
//    if (i->mask & IN_DELETE)        printf("IN_DELETE ");
//    if (i->mask & IN_DELETE_SELF)   printf("IN_DELETE_SELF ");
//    if (i->mask & IN_IGNORED)       printf("IN_IGNORED ");
//    if (i->mask & IN_ISDIR)         printf("IN_ISDIR ");
//    if (i->mask & IN_MODIFY)        printf("IN_MODIFY ");
//    if (i->mask & IN_MOVE_SELF)     printf("IN_MOVE_SELF ");
//    if (i->mask & IN_MOVED_FROM)    printf("IN_MOVED_FROM ");
//    if (i->mask & IN_MOVED_TO)      printf("IN_MOVED_TO ");
//    if (i->mask & IN_OPEN)          printf("IN_OPEN ");
//    if (i->mask & IN_Q_OVERFLOW)    printf("IN_Q_OVERFLOW ");
//    if (i->mask & IN_UNMOUNT)       printf("IN_UNMOUNT ");
//    printf("\n");
}




@end
