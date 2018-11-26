//
//	MPWFilterStream.m
//
//	generic subclass for 'pipes',
//	streams that filter output to
/*
    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

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


-(void)forwardBytes:(const void*)data length:(unsigned long)count
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
        TARGET_APPEND( (char*)data, count );
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
    if ( [_target respondsToSelector:@selector(psDecoder)] ) {
        base=[_target psDecoder];
    }
    return [NSString stringWithFormat:@" %@ %@ ",base,[self psDecode]];
}

+testSelectors
{
    return [NSArray array];
}



@end


