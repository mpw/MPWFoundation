//
//	MPWASCII85Stream.h
//
//	generic subclass for 'pipes',
//	streams that filter output to
/*
    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

*/



#import <MPWFoundation/MPWFilterStream.h>

@interface MPWASCII85Stream:MPWFilterStream
{
    unsigned long base256;
    int phase, nonzero, base85digit[5], index, nz;
    long inbytes;
    long outbytes;
	BOOL flushed;
}

@end

