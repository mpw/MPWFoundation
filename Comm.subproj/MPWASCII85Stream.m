//
//	MPWASCII85Stream.m
//
/*
    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

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
    if ( self=[super initWithTarget:aStream]) {
        base256 = 0;
        phase = 0;
        inbytes = 0;
        outbytes = 0;
    }

    return self;
}


-(void)appendBytes:(const void*)data length:(NSUInteger)count
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
                if((base85digit[index] = (int)(base256 / divarray[index])) != 0)
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


