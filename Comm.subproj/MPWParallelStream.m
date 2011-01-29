//
//	MPWParallelStream.m
//
//	implementation of a class to talk to PC parallel devices
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


#import "MPWParallelStream.h"

#import <Foundation/NSString.h>

#import <libc.h>
#import <stdio.h>
#import <stdlib.h>

#define DRIVER_PRIVATE				//	we want access to pp0 ioctl's
#include <bsd/dev/i386/pp_extern.h>


@implementation MPWParallelStream


-(BOOL)isReady
{
	int sw;

	if ( fd >= 0)
	{
		if ( ioctl( fd, PPIOCSW, &sw ) >= 0 )
		{
			if ( (sw & PP_ST_NOPAPER) == PP_ST_NOPAPER )
			{
//				[self printError:"Out of Paper"];
			}
			else if ( (sw & PP_ST_BUSY) == PP_ST_BUSY )
			{
//				[self printError:"Printer not responding\n(Power, Off-Line, Jam)"];
				ioctl( fd, PPIOCSW, &sw );
					if ( (sw & PP_ST_BUSY) == PP_ST_BUSY )
				{
					printf(  "Real busy\n" );
					fflush(stdout);
					sleep(2);
				}
			}
			else
				return YES;
		}	
	}
	return NO;
}

-(void)appendBytes:(const void*)bytes length:(unsigned int)len
{
    
}

-(void)openDeviceUnit:(int)unit
{
	[self openDevice:[NSString stringWithFormat:@"/dev/pp%d",unit]];
	return;
}

-(void)openDevice
{
	[self openDeviceUnit:0];
}

-ppOptionset
{
	{
		int param;

		//---	wait 200 ms after a BUSY from printer
		//---	return max. 200 times ( 40s total timeout )

		param=200;	
		ioctl( fd, PPIOCSRINTERVAL, &param);
		ioctl( fd, PPIOCSRETRIES, &param);
		
		
		ioctl( fd, PPIOCGIHDELAY, &param);
		printf("int handler delay = %d us\n",param);

		ioctl( fd, PPIOCGIOTDELAY, &param);
		printf("IOTask thread delay = %d us\n",param);

		ioctl( fd, PPIOCGMINPHYS, &param);
		printf("max chunk size = %d\n",param);

		ioctl( fd, PPIOCGBSIZE, &param);
		printf("block size = %d\n",param);

		ioctl( fd, PPIOCGRINTERVAL, &param);
		printf("busy retry interval = %d (what unit?)\n",param);

		ioctl( fd, PPIOCGRETRIES, &param);
		printf("max busy retries = %d\n",param);

		ioctl( fd, PPIOCGSREG, &param);
		printf("status register = %x \n",param);

		ioctl( fd, PPIOCGCREG, &param);
		printf("control register = %x \n",param);

		ioctl( fd, PPIOCGCREGDEF, &param);
		printf("control register defaults = %x us\n",param);
	}
	
	return self;
}

-(void)setOptionsFromTable:printInfo
{
	//---	first try full device name
	
	//---	alternatively, a Unit name is also OK
	
}
@end


