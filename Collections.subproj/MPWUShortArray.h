/* MPWUShortArray.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWObject.h>

@interface MPWUShortArray : MPWObject
{
    unsigned long	capacity;
    unsigned long	count;
    unsigned short	*data;
}

-initWithCapacity:(NSUInteger)newCap;
-initWithUshorts:(const unsigned short*)newData count:(unsigned)count;
-(unsigned short*)ushorts;
-(unsigned)ushortAtIndex:(unsigned long)index;
-(unsigned)lastUshort;
-(NSUInteger)count;
-(void)appendUshorts:(const unsigned short*)newData count:(unsigned)newCount;
-(void)pushUshort:(unsigned short)newShort;
-(void)popUshort;
-(void)swapFromBigEndian;

@end
