//
//	MPWLZWStream.h
//
//	generic subclass for 'pipes',
//	streams that filter output to
/*
    Copyright (c) 1997-2017 by Marcel Weiher. All rights reserved.

R

*/



#import <MPWFoundation/MPWFilterStream.h>


#define MAXSTRINMPW	4096		  /* using 12 bit max codes */

@interface MPWLZWStream:MPWFilterStream
{
	//---	compressor state

	int 		codeWidth;
	int 		bitsInAcc;
	unsigned long acc;
	int			nextIndex;
	short		suffixCount[MAXSTRINMPW];
	short 		directTable[MAXSTRINMPW][256];
	unsigned char   usedEntries[MAXSTRINMPW][256];
	long incount;
	long outcount;		/* Input/output tally */
	short lastCode;
	BOOL firstByte;
	BOOL flushed;
	BOOL ignoreCleanup;
}

boolAccessor_h( ignoreCleanup, setIgnoreCleanup )

@end

