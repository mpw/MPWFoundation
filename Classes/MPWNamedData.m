/*
  MPWNamedData.m
  MPWFoundation

    Created by Marcel Weiher on 24/09/2005.
    Copyright (c) 2005-2012 by Marcel Weiher. All rights reserved.

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

//

#import <MPWFoundation/MPWFoundation.h>

@interface NSCoder(namedDataCoding)

-(void)encodeNamedData:(MPWNamedData*)data;
-decodeNamedData:(MPWNamedData*)data;

@end

@implementation MPWNamedData

objectAccessor( NSData, data, setData )
objectAccessor( NSString, name, setName )

-initWithData:(NSData*)aData name:(NSString*)filename
{
    self = [self init];
    [self setData:aData];
    [self setName:filename];
    return self;
}

-initWithContentsOfFile:(NSString*)filename
{
    return [self initWithData:[NSData dataWithContentsOfFile:filename] name:filename ];
}

-initWithContentsOfMappedFile:(NSString*)filename
{
    return [self initWithData:[NSData dataWithContentsOfMappedFile:filename] name:filename];
}

-(void)writeToFileAtomically:(BOOL)atomically
{
    [[self data] writeToFile:[self name] atomically:atomically];
}

-(NSUInteger)length
{
    return [[self data] length];
}

-(const void*)bytes
{
    return [[self data] bytes];
}

-(void)dealloc
{
    [data release];
    [name release];
    [super dealloc];
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeNamedData:self];
}

-initWithCoder:(NSCoder*)aCoder
{
    return [aCoder decodeNamedData:self];
}

-(void)encodeWithXmlCoder:(NSCoder*)aCoder
{
    [aCoder encodeNamedData:self];
}

-initWithXmlCoder:(NSCoder*)aCoder
{
    return [aCoder decodeNamedData:self];
}


-(void)writeOnByteStream:stream
{
    [stream writeObject:[self data]];
}

-stringValue
{
    return [[self data] stringValue];
}

-replacementObjectForCoder:aCoder
{
    return self;
}

-classForCoder
{
    return isa;
}

@end

@implementation NSCoder(namedDataCoding)

-(void)encodeNamedData:(MPWNamedData*)namedData
{
    id name=[namedData name];
    id data=[namedData data];
    encodeVar( self, data );
    encodeVar( self, name );
}
-decodeNamedData:(MPWNamedData*)namedData
{
    id name;
    id data;
    decodeVar( self, data );
    decodeVar( self, name );
    return [namedData  initWithData:data name:name];
}


@end
