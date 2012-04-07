/*
//	MPWLZWStream.m
//
//	compresses incoming bytes via LZW to output
//	streams that filter output to
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

//---	Class Definition
#if 0

#import "MPWLZWStream.h"

//---	C includes

#import <strings.h>

#define EOD			  257			  /* End of Data marker */
#define CLR			  256			  /* Clear Table Marker */
#define MAXSTRINGS  4096		  /* using 12 bit max codes */
#ifndef TRUE
#define TRUE		  (1==1)
#define FALSE		  !TRUE
#endif

@implementation MPWLZWStream

static void (*addString)(id, SEL, int,int)=(void (*)(id, SEL, int,int))nil;
static void (*sendCode)(id, SEL, int)=(void (*)(id, SEL, int))nil;


static	int	initialized=0;

boolAccessor( ignoreCleanup, setIgnoreCleanup )


-(void)_initializeDict
{
    int index;
    initialized++;
//  fprintf(stderr,"_initializeDict\n");
    for ( index=0; index<MAXSTRINGS;index++)
    {	
        short *dTable=&directTable[index][0];
        unsigned char *used=&usedEntries[index][0];
        unsigned char *max=used + suffixCount[index];
        while (used < max)
        {
            dTable[*used++]=-1;
        }
/*
        int j;
        for (j=0;j<256;j++) {
            directTable[index][j]=-1;
        }
*/
        suffixCount[index]=0;
    }
    nextIndex = EOD + 1;
    codeWidth = 9;
}

-(void)flushAccumulator
{
	if ( bitsInAcc != 0 ) 
	{
        char c_out=acc>>24;
        putc_stream( self, c_out );
        outcount++;
	}
}

-(void)_sendCode:(short)theCode
{
    acc += (unsigned long) theCode << (32 - codeWidth - bitsInAcc);
    bitsInAcc += codeWidth;
    if (bitsInAcc >= 16)
    {
        char c_out=acc>>24;
        putc_stream( self, c_out );
        c_out=acc>>16;
        putc_stream( self, c_out );
        acc = acc << 16;
        bitsInAcc -= 16;
        outcount+=2;
    }
    else if (bitsInAcc >= 8)
    {
        char c_out=acc>>24;
        putc_stream( self, c_out );
        acc = acc << 8;
        bitsInAcc -= 8;
        outcount++;
    }

    if(theCode == CLR)
    {
        [self _initializeDict];
    }

    if(theCode == EOD )
    {
		[self flushAccumulator];
	}

    return;
}


-(void)_addString:(short)prefix suffix:(short)suffix
{
	 
	 next->prefix = prefix;
	 next->suffix = suffix;
	 next->next = prev->next;
	 next->flag = MUSTCLEAR;
	 prev->next = nextIndex;
	if ( prev->flag == MUSTCLEAR )
	{
		memset( prev->next_by_char, 0 , sizeof(stringarray[prefix].next_by_char));
		prev->flag=HAVECLEARED;
	}
	fprintf(stderr,"nextIndex = %d for prefix: %d suffix: %d\n",nextIndex,prefix,suffix);
	prev->next_by_char[suffix]=nextIndex+1;	

	 if(++nextIndex >> codeWidth)
	 {
		  if(++codeWidth > 12)
		  {
				--codeWidth;
				[self _sendCode:CLR];
		  }
	 }
	 return;
}


-(void)appendBytes:(const void*)data length:(unsigned int)count
{
    short thisCode;
    unsigned const char *bytes=data;
//	NSLog(@"MPWLZWStream: write %d bytes",count);
	if ( count > 0 ) {
		if ( firstByte == YES)
		{
			lastCode = *bytes++;
			count--;
			firstByte=NO;
		}
		
		while (count--)
		{
			int index;
			thisCode=*bytes++;
			if ( (index=directTable[lastCode][thisCode]) < 0)
			{
				sendCode(self,@selector(_sendCode),lastCode);
				directTable[lastCode][thisCode]=nextIndex;
				usedEntries[lastCode][suffixCount[lastCode]++]=thisCode;
				if(++nextIndex >> codeWidth)
				{
					if(++codeWidth > 12)
					{
						--codeWidth;
						[self _sendCode:CLR];
					}
				}
				lastCode = thisCode;
			}
			else
			{
				lastCode=index;
			}
		}
	}
}

-(void)openDevice
{
}

-(void)flushLocal
{
	if (!flushed ) {
		[self _sendCode:lastCode];
		if ( !ignoreCleanup ) {
			[self _sendCode:EOD];
		} else {
			[self flushAccumulator];
		}
		[super flushLocal];
		flushed=YES;
	} else {
		NSLog(@"%@ already flushed",self);
	}
}

-(NSString*)psDecode
{
    return @" /LZWDecode filter ";
}

-initWithTarget:aStream
{
    int i;
    [super initWithTarget:aStream];

    bitsInAcc = 0;
    acc=0;
    incount = 0;
    outcount = 0;		/* Input/output tally */
    codeWidth = 9;
    if (!addString)
        addString=(void (*)(id, SEL, int,int))[self methodForSelector:@selector(_addString:suffix:)];
    if (!sendCode)
        sendCode=(void (*)(id, SEL, int))[self methodForSelector:@selector(_sendCode:)];
    for (i=0;i<MAXSTRINGS;i++) {
        int j;
        for (j=0;j<256;j++) {
            directTable[i][j]=-1;
        }
        suffixCount[i]=0;
    }
    [self _sendCode:CLR];
    firstByte=YES;
    return self;
}

@end
#endif 


