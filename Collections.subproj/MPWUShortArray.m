/* MPWUShortArray.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


#import "MPWUShortArray.h"
#import <Foundation/Foundation.h>

@implementation MPWUShortArray

-initWithCapacity:(NSUInteger)newCap
{
    if (self = [super init]) {
        data = calloc( newCap+10 , sizeof(unsigned short));
        capacity=newCap;
        count=0;
    }
    return self;
}

-initWithUshorts:(const unsigned short*)newData count:(unsigned)newCount
{
    self = [self initWithCapacity:newCount+2];
    [self appendUshorts:newData count:newCount];
    return self;
}
-(unsigned short*)ushorts
{
    return data;
}
-(unsigned)ushortAtIndex:(unsigned)index
{
    if ( index < count ) {
        return data[index];
    } else {
        [NSException raise:@"range exception" format:@"accesing ushort at index %d max %d",index,count];
        return -1;
    }
}

-(unsigned)lastUshort
{
    return [self ushortAtIndex:count-1];
}

-(NSUInteger)count
{
	return count;
}

-(void)appendUshorts:(const unsigned short*)newData count:(unsigned)newCount
{
    if ( newCount + count <= capacity ) {
        memcpy( data+count, newData, newCount*sizeof(unsigned short));
        count+=newCount;
    } else {
        [NSException raise:@"capacity exceeded" format:@"%d new + %d current exceeds capacity %d",newCount,count,capacity];
    }
        
}

-(void)pushUshort:(unsigned short)newShort
{
    [self appendUshorts:&newShort count:1];
}

-(void)popUshort
{
    if ( count > 0 ) {
        count--;
    } else {
        [NSException raise:@"pop of empty ushort array" format:@"pop of empty ushort array"];
    }
}

//#ifdef Darwin
-(void)swapFromBigEndian
{
    unsigned short *cur=(unsigned short*)data;
    unsigned short *end=((unsigned short*)data)+count;
    while ( cur < end ) {
        *cur=NSSwapBigShortToHost( *cur );
        cur++;
    }
}
//#endif

-(NSString*)description
{
	id str=[NSMutableString string];
	int i;
	[str appendFormat:@"<%@ %p: count: %d elements:",[self class],self,count];
	for (i=0;i<count;i++) {
		[str appendFormat:@" %d",[self ushortAtIndex:i]];
	}
	[str appendFormat:@">"];
	return str;
}

@end

