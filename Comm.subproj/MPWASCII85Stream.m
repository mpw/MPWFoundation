//
//	MPWASCII85Stream.m
//
/*
    Copyright (c) 1997-2011 by Marcel Weiher. All rights reserved.

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


#import "MPWASCII85Stream.h"


static long divarray[5] = { (long) 1, (long) 85, (long) 7225, (long) 614125,
						   (long) 52200625 };

@implementation MPWASCII85Stream

static void lineLimited_putc( MPWASCII85Stream* self, unsigned char byte )
{
    //---	limit maximum line-length
    //---	by outputting a linefeed
    //---	every 60 characters (

    if (self->outbytes % 60 == 0 && self->outbytes > 0)
        putc_stream( self, '\n');
    putc_stream( self, byte );
    self->outbytes++;
}

-initWithTarget:aStream
{
    [super initWithTarget:aStream];

    base256 = 0;
    phase = 0;
    inbytes = 0;
    outbytes = 0;


    return self;
}


-(void)appendBytes:(const void*)data length:(unsigned long)count
{
    short theChar;
    unsigned const char *bytes=data;

    while (count--)
    {
        theChar=*bytes++;
        base256 += theChar << (8 * (3 - phase++));

        if(phase == 4)
        {
            for(index = 4; index >= 0; index--)
            {
                if((base85digit[index] = base256 / divarray[index]) != 0)
                {
                    nz = !0;
                }
                base256 = base256 % divarray[index];
            }

            if(nz)
            {
                for(index = 4; index >= 0; index--)
                {
                    unsigned char ch = base85digit[index] + '!';
//						[self forwardBytes:&ch length:1];
                    lineLimited_putc( self, ch );
                }
            } else
            {
                unsigned char ch='z';
//					[self forwardBytes:&ch length:1];
                lineLimited_putc( self, ch );
            }
            phase = 0;
            base256 = 0;
        }
    }
}

-(void)flushLocal
{
	if (!flushed ) {
		if(phase != 0)
		{
			for(index = 4; index >= (4-phase); index--)
			{
				char ch=base256 / divarray[index] + '!';
//			[self forwardBytes:&ch length:1];
				lineLimited_putc( self, ch );
				base256 = base256 % divarray[index];
			}
		}
		[self forwardBytes:"~>\n" length:3];
		[super flushLocal];
		flushed=YES;
	} else {
		NSLog(@"%@ already flushed",self);
	}
}

-(NSString*)psDecode
{
    return @" /ASCII85Decode filter ";
}


@end


