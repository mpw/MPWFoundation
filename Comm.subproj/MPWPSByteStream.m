/*
    MPWPSByteStream.m created by marcel on Sat 17-Jan-1998
    Copyright (c) 1998-2006 Marcel Weiher. All rights reserved.

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


#import "MPWPSByteStream.h"

@interface NSObject(psByteStreaming)

-(void)writeOnPSByteStream:aStream;

@end
@implementation NSObject(psByteStreaming)

-(void)writeOnPSByteStream:aStream
{
    [self writeOnByteStream:aStream];
}

@end


@implementation MPWPSByteStream

-(SEL)streamWriterMessage
{
    return @selector(writeOnPSByteStream:);
}

-(void)writeEnumerator:(NSEnumerator*)e
{
    [self writeEnumerator:e spacer:@" "];
}

-(void)writeArray:(NSArray*)anArray
{
    [@"[ " writeOnPSByteStream:self];
    [super writeArray:anArray];
    [@" ] " writeOnPSByteStream:self];
}

-(void)writeDictionary:(NSDictionary*)dict
{
    [@"<< " writeOnPSByteStream:self];
    [super writeDictionary:dict];
    [@" >> " writeOnPSByteStream:self];
}

-(void)writeObject:anObject forKey:aKey
{
    [@"/" writeOnPSByteStream:self ];
    [[aKey stringValue] writeOnPSByteStream:self];
    [@" " writeOnPSByteStream:self];
    [anObject writeOnPSByteStream:self];
    [@" " writeOnPSByteStream:self];
}

-(void)lineto:(float*)coords
{
    [self printf:@"%g %g lineto\n",coords[0],coords[1]];
}

-(void)moveto:(float*)coords
{
    [self printf:@"%g %g moveto\n",coords[0],coords[1]];
}

-(void)curveto:(float*)coords
{
    [self printf:@"%g %g %g %g %g %g curveto\n",
        coords[0],coords[1],
        coords[2],coords[3],
        coords[4],coords[5]];
}

-(void)closepath
{
    [self printf:@"closepath\n"];
}

@end


