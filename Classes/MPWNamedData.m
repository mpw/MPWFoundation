/*
  MPWNamedData.m
  MPWFoundation

    Created by Marcel Weiher on 24/09/2005.
    Copyright (c) 2005-2017 by Marcel Weiher. All rights reserved.

R

*/

//

#import <MPWFoundation/MPWNamedData.h>
#import <objc/runtime.h>
#import <AccessorMacros.h>
#import "CodingAdditions.h"
#import "NSStringAdditions.h"
#import <MPWWriteStream.h>


@interface NSCoder(namedDataCoding)

-(void)encodeNamedData:(MPWNamedData*)data;
-decodeNamedData:(MPWNamedData*)data;

@end



@implementation MPWNamedData

objectAccessor(NSData*, data, setData )
objectAccessor(NSString*, name, setName )

-initWithData:(NSData*)aData name:(NSString*)filename
{
    self = [self init];
    [self setData:aData];
    [self setName:filename];
    return self;
}

-initWithContentsOfFile:(NSString*)filename options:(NSDataReadingOptions)readOptionsMask error:(NSError * _Nullable * _Nullable)errorPtr
{
    return [self initWithData:[NSData dataWithContentsOfFile:filename options:readOptionsMask error:errorPtr ] name:filename ];
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
    return object_getClass(self);
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
