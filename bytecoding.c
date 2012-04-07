/*
    Copyright (c) 2001-2012 by Marcel Weiher. All rights reserved.

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

#include "bytecoding.h"
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>

void
limited_rle_decode( unsigned char *out, unsigned char **outendp, const unsigned char *in, const unsigned char **inendp )
{
    unsigned char *outend = *outendp;
    const unsigned char *inend = *inendp;
    while ( in < inend && out < outend ) {
        unsigned char rlecode=*in;
        const unsigned char *inrunend=in;
        unsigned char *outrunend=out;
//        fprintf(stderr,"in-byte=%d\n",rlecode);
        if ( rlecode < 128 ) {
            inrunend+=rlecode+2;
            outrunend+=rlecode+1;
        } else if ( rlecode > 128 ) {
            inrunend+=2;
            outrunend+=257-rlecode;
        } else {
            break;
        }
        if ( inend >= inrunend && outend > outrunend ) {
            if ( rlecode < 128 ) {
//               fprintf(stderr,"copying %d bytes",outrunend-out);
                memcpy( out, in+1, outrunend-out );
            } else {
//                fprintf(stderr,"setting %d bytes to %d",outrunend-out,in[1]);
                memset( out, in[1], outrunend-out );
            }
            out=outrunend;
            in=inrunend;
        } else {
            break;
        }
    }
    *inendp=in;
    *outendp=out;
}


unsigned int
limited_rle_encode(unsigned char *out,const unsigned char *in, int  width, int maxRLE)
{
   int used = 0;
   int crun,cdata;
   unsigned char run;

   if(in != 0) { /* Data present */

      crun = 1;

      while(width > 0) { /* something to compress */

         run = in[0];

         while((width > crun) && (run == in[crun]))
             if(++crun == maxRLE)
                 break;

         if((crun > 2) || (crun == width)) { /* use this run */

            *out++ = (257 - crun) & 0xff; *out++ = run; used += 2;

            width -= crun; in    += crun;
            crun = 1;

         } else {                            /* ignore this run */

            for(cdata = crun; (width > cdata) && (crun < 4);) {
               if(run  == in[cdata])
                   crun += 1;
               else
                   run = in[cdata], crun  = 1;
               if(++cdata == maxRLE)
                   break;
            }

             if(crun < 3)
                 crun   = 0;    /* ignore trailing run */
             else
                 cdata -= crun;

             *out++ = cdata-1;     used++;
             memcpy(out,in,cdata); used += cdata; out   += cdata;

             width -= cdata; in    += cdata;

         }              /* use/ignore run */

      }                  /* something to compress */

   } else {         /* Empty scans to fill bands */
     while(width > 0) {
         crun   = width > 129 ? 129 : width;
         width -= crun;
         *out++ = (257 - crun) & 0xff;
         *out++ = 0;
         used  += 2;
      }
   }                /* Data present or empty */
   return used;
}

unsigned int
rle_encode(unsigned char *out,const unsigned char *in, int  width)
{
    return limited_rle_encode( out, in, width, 128);
}

static unsigned int output_delta( unsigned int offset, unsigned int length , const unsigned char *diff_bytes, unsigned char *target )
{
    int curLength;
    unsigned char *out=target;
    
//	printf("\tdiff at relative offset %d of length %d\n",offset,length);
    while ( length > 0 )
    {
        int firstOffset=offset < 31 ? offset : 31;

        curLength= length < 8 ? length : 8;
//		printf("\t\tgoing to output diff as %d %d\n",curLength-1, firstOffset);
        *out++ = ((curLength-1 ) << 5 ) | (firstOffset);
        if ( offset == 31 )
            *out++=0;
        offset -= firstOffset;
        while ( offset > 0 )
        {
            firstOffset = offset < 255 ? offset : 255;
//			printf("\t\t\textension byte: %d\n", firstOffset);
            *out++=firstOffset;
            if ( offset == 255 )
                *out++=0;
            offset -= offset < 255 ? offset : 255;
        }
        memcpy( out, diff_bytes, curLength );
        out+=curLength;
        diff_bytes+=curLength;
        length-=curLength;
    }
//	printf("\tencoded to %d bytes\n",out-target);
    return out - target;
}
#define	EQUAL	0
#define	DIFF	1

unsigned int
delta_row_encode(unsigned char *dest, const unsigned char *src, unsigned int count,const unsigned char * seed)
{
    int state;
    int i,j;
    unsigned char *out;
    int state_changes[count];
    int lengths[count];

    j=0;
    state=EQUAL;
    for ( i=0; i<count;i++)
    {
        switch ( state )
        {
            case EQUAL:
                while ( src[i] == seed[i] && i< count)
                {
                    i++;
                }
                if ( i<count )
                {
                    state_changes[j]=i;
                    state=DIFF;
                }
                break;
            case DIFF:
                while ( src[i] != seed[i] && i< count)
                {
                    i++;
                }
                if ( i< count  )
                {
                    lengths[j]=i - state_changes[j];
                    j++;
                    state=EQUAL;
                }
                break;
        }
    }
    if ( state == DIFF )
    {
        lengths[j]=i - state_changes[j];
        j++;
    }
    out=dest;
//	printf("row:\n");
    for (i=0;i<j;i++)
    {
//		printf("\trun: %d %d\n",state_changes[i],lengths[i]);
        out+=output_delta( i>0 ? state_changes[i] - state_changes[i-1] - lengths[i-1]: state_changes[i] , lengths[i] , src+state_changes[i], out );
    }
//	return 5000;
    return out-dest;
}

unsigned nonzero_length( const unsigned char *source, unsigned int len )
{
    const unsigned char *cur=source+len-1;
    while ( cur >= source && *cur==0 && ((unsigned long)cur & 3)!=3) {
        cur--;
    }
    while ( cur >= source+3 && (*(unsigned long*)(cur-3))==0 ) {
        cur-=4;
    }
    while ( cur >= source && *cur==0 ) {
        cur--;
    }
    return cur-source+1;
}

void hexencode( const unsigned char *source, unsigned char *dest, unsigned int sourceLen )
{
    static unsigned char toHex[]="0123456789abcdef";
    while ( sourceLen-- > 0 ) {
        unsigned char unencoded=*source;
        *dest++ = toHex[ unencoded >> 4 ];
        *dest++ = toHex[ unencoded & 15 ];
        source++;
    }
}

int hexdecode( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target, int skipNonDigits )
{
    unsigned const char *cur=from;
    static unsigned char *hex2int_map=NULL;
    int written=0;
    int odd=0;
    if ( hex2int_map == NULL) {
        unsigned char c;
		hex2int_map=calloc( 256, 1 );
        bzero( hex2int_map,  256 );
        for ( c='0'; c<='9';c++ ) {
            hex2int_map[c]=c-'0';
        }
        for ( c='A'; c<='F'; c++) {
            hex2int_map[c]=(c-'A') + 10;
        }
        for ( c='a'; c<='f'; c++) {
            hex2int_map[c]=(c-'a') + 10;
        }
//        inited=1;
    }
    while ( written < length  && cur<end) {
        unsigned char r;
        while ( isspace(*cur) && cur<end ) {
            cur++;
        }
        //--- non-hex digits are simply skipped
        if ( cur < end && isxdigit( *cur ) ) {
            r=hex2int_map[*cur++]<<4;
            if ( cur < end ) {
                //--- hex digits can be split
                while ( isspace(*cur) && cur<end ) {
                    cur++;
                }
                r|=hex2int_map[*cur++];
                *to++=r;
                written++;
            } else {
                *to++=r;
                odd=1;
            }
        } else {
            if ( skipNonDigits || isspace( *cur ) ) {
                cur++;
                continue;
            } else {
                break;
            }
        }
    }
    if ( written_target ) {
        *written_target=written;
    }
    if ( odd_target ) {
        *odd_target=odd;
    }
    return cur-from;
}


int hexdecodeSkip( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target )
{
    return hexdecode( from, end, to,  length, written_target, odd_target, 1 );

}

int hexdecodeNoSkip( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target )
{
    return hexdecode( from, end, to,  length, written_target, odd_target, 0 );

}


unsigned hashCStringLen( const unsigned char *ch, unsigned len )
{
    unsigned hashResult = 0, hash2;
    if (ch) {
        while ( len-- > 0) {
            hashResult <<= 4;
            hashResult += *ch++;
            if((hash2 = hashResult & 0xf0000000))
                hashResult ^= (hash2 >> 24) ^ hash2;
        }
    }
    return hashResult;
}

#if 0
#ifndef Darwin

unsigned NSHashCString( unsigned char *str, int n )
{
	unsigned hash = 0,hash2;
	int i;

	for (i=0;i<n;i++) {
		hash<<=4;
		hash += str[i];
		if ((hash2 = hash & 0xf0000000 )) {
			hash ^=(hash2 >> 24) ^hash2;
		}
	}
	return hash;
}

#endif
#endif
