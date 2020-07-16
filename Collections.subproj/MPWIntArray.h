//
//  MPWIntArray.h
//  MPWFoundation
//
//  Created by Marcel Weiher on Sat Dec 27 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.
*/

//

#import <MPWFoundation/MPWObject.h>
#import <MPWFoundation/MPWWriteStream.h>


@interface MPWIntArray : MPWObject<Streaming> {
	int *data;
	unsigned long count,capacity;
}

+array;
-(int)integerAtIndex:(unsigned)index;
-(instancetype)initFromInt:(long)start toInt:(long)stop step:(long)step;
-(void)addIntegers:(int*)intArray count:(unsigned long)numIntsToAdd;
-(void)addInteger:(int)anInt;
-(void)addObject:anObject;
-(void)replaceIntegerAtIndex:(unsigned long)anIndex withInteger:(int)anInt;
-(NSUInteger)count;
-(void)reset;
-(int*)integers;
-(int)lastInteger;
-(void)removeLastObject;
-(void)do:(void(^)(int))block;
-(instancetype)select:(BOOL(^)(int))block;

-(void)writeInteger:(long)anInt;
@end
