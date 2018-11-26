//
//	MPWFilterStream.h
//
//	generic subclass for 'pipes',
//	streams that filter output to
/*
    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

*/



#import <MPWFoundation/MPWByteStream.h>

#define	BUFMAX	8192

@interface MPWFilterStream:MPWByteStream
{
@public
    char buffer[BUFMAX+10];
    int	bufSize;
}

-(void)forwardBytes:(const void*)bytes length:(unsigned long)len;

-(NSString*)psDecoder;
-(void)flushLocal;

@end


inline static void putc_stream( MPWFilterStream* stream, unsigned char byte )
{
	if ( stream->bufSize < BUFMAX )
            stream->buffer[stream->bufSize++]=byte;
	else
            [stream forwardBytes:&byte length:1];
}

