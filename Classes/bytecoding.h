/*
    Copyright (c) 2001-2017 by Marcel Weiher. All rights reserved.

R

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

unsigned hashCStringLen( const unsigned char *cstring, unsigned long len );


