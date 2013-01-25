//
//	MPWFilterStream.m
//
//	generic subclass for 'pipes',
//	streams that filter output to
/*
    Copyright (c) 1997-2012 by Marcel Weiher. All rights reserved.

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


#import "MPWFilterStream.h"

@implementation MPWFilterStream


-(void)flushBuffer
{
    if ( bufSize > 0 )
    {
        TARGET_APPEND( buffer, bufSize );
        bufSize=0;
    }
}

-(void)flushLocal
{
    [self flushBuffer];
}


-(void)forwardBytes:(const void*)data length:(unsigned int)count
{
    if ( count + bufSize >= BUFMAX && bufSize > 0 )
        [self flushBuffer];
    if ( count+bufSize < BUFMAX )
    {
        memcpy( buffer+bufSize, data, count );
        bufSize+=count;
    }
    else
    {
        TARGET_APPEND( data, count );
    }
}

-(void)appendBytes:(const void*)data length:(NSUInteger)count
{
    [self forwardBytes:data length:count];
}


-(NSString*)psDecode
{
    return @"";
}

-(NSString*)psDecoder
{
    id base=@"";
    if ( [target respondsToSelector:@selector(psDecoder)] ) {
        base=[target psDecoder];
    }
    return [NSString stringWithFormat:@" %@ %@ ",base,[self psDecode]];
}

+testSelectors
{
    return [NSArray array];
}



@end


