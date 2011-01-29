//
//	MPWJetStream.m
//
//	implementation of a class to talk to the HP JetDirect network interface
/*
    Copyright (c) 1997-2006 Marcel Weiher. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

    Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the distribution.

    Neither the name Marcel Weiher nor the names of contributors may
    be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/




//---	Class Definition

#import "MPWJetStream.h"

//---	Foundation kit

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSDate.h>

//---	Networking C lib

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <libc.h>

//---	ANSI C

#import <stdio.h>
#import <stdlib.h>

//#import <includes.h>

#define DEF_PRINTER_PORT	9100

#define OPEN_RETRY_DELAY         15	/* delay for open attempts */
#define WAIT_RETRY_DELAY         5	/* delay while waiting for print */
#define LP_SUCCESS	0
#define LP_RETRY	1
#define LP_FAILED	2

#define ERRSTR strerror(errno)

#define	ASYNC

@implementation MPWJetStream



-initWithName:(NSString*)name port:(int)portNo
{
    [super init];

    hostName= [name retain];
    port = portNo;

    watchDog = [[NSDate alloc] init];
    [self openDevice];
    return self;
}

-(void)appendBytes:(const void*)dataIn length:(unsigned int)len
{
    [self checkWatchDog];
    [super appendBytes:dataIn length:len];
    [self resetWatchDog];
    return;
}

#define	waiting_til_ready	1

-(void)openDevice
{
    if ( fd < 0 )
    {
        struct hostent *host;       /* host entry pointer */
        char *hostname=(char*)[hostName cString];
        struct sockaddr_in sin;
        if ((host = gethostbyname (hostname)) == NULL)
        {
            fprintf(stderr, "JetTalker connecting to %s\n",hostname);
            perror( "JetTalker: unknown host" );
        }
        memset((char *) &sin,0,sizeof (sin));
        sin.sin_family = AF_INET;
        memcpy((caddr_t) & sin.sin_addr,host->h_addr,  host->h_length);
        sin.sin_family = host->h_addrtype;
        sin.sin_port = htons (port);

        do
        {	/* open the socket. */
            if (waiting_til_ready)
            {
                /*				setstatus ("Connecting to printer...", hostname); */
            }

            if ((fd = socket (AF_INET, SOCK_STREAM, 0)) < 0)
            {
                perror("JetTalker can't open socket ");
            }

            if (connect (fd, (struct sockaddr *) & sin, sizeof (sin)) == 0)
            {
                int opt=1;
                printf("sesockopt=%d\n",setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, (char*)&opt,4));

                break;
            }
            else
            {
                [self closeDevice];
//				close (fd);
                if (waiting_til_ready)
                {
                    sleep (WAIT_RETRY_DELAY);
                }
                else
                {
                    /* setstatus ("Retrying connection - offline? (%s)", ERRSTR); */
                    sleep (OPEN_RETRY_DELAY);
                }	
            }
        } while (1);                /* block forever */
    }
    [self resetWatchDog];
}

-(void)setOptionsFromTable:printInfo
{
	[self setHost:[printInfo objectForKey:@"HostName"]];
	return;
}

-(void)resetWatchDog
{
	[watchDog release];
	watchDog=[[NSDate alloc] initWithTimeIntervalSinceNow:30];	
}
-(void)checkWatchDog
{
	NSDate *now=[[NSDate alloc] initWithTimeIntervalSinceNow:0];

	if ( [now compare:watchDog] == NSOrderedDescending )
	{
		[self closeDevice];
		[self openDevice];
	}
	[now release];
}

@end


