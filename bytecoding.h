/*
    Copyright (c) 2001-2011 by Marcel Weiher. All rights reserved.

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


void limited_rle_decode( unsigned char *outstart, unsigned char **outendp, const unsigned char *in, const unsigned char **inendp );
unsigned int rle_encode(unsigned char *out,const unsigned char *in, int  width);
unsigned int limited_rle_encode(unsigned char *out,const unsigned char *in, int  width, int maxRLE);
unsigned int delta_row_encode(unsigned char *out, const unsigned char *in, unsigned int count,const unsigned char * seed);
unsigned nonzero_length( const unsigned char *source, unsigned int len );
void hexencode( const unsigned char *source, unsigned char *dest, unsigned int sourceLen );
int hexdecode( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target, int doSkip );
int hexdecodeSkip( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target );
int hexdecodeNoSkip( const unsigned char *from, const unsigned char *end, unsigned char *to, unsigned int length,unsigned int *written_target, int *odd_target );

unsigned hashCStringLen( const unsigned char *cstring, unsigned len );


