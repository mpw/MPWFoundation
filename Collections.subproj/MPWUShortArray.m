/* MPWUShortArray.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
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
-(unsigned)ushortAtIndex:(unsigned long)index
{
    if ( index < count ) {
        return data[index];
    } else {
        [NSException raise:@"range exception" format:@"accesing ushort at index %ld max %ld",index,count];
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
        [NSException raise:@"capacity exceeded" format:@"%d new + %ld current exceeds capacity %ld",newCount,count,capacity];
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
	[str appendFormat:@"<%@ %p: count: %ld elements:",[self class],self,count];
	for (i=0;i<count;i++) {
		[str appendFormat:@" %d",[self ushortAtIndex:i]];
	}
	[str appendFormat:@">"];
	return str;
}

@end

