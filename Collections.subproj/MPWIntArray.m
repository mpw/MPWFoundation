//
//  MPWIntArray.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Sat Dec 27 2003.
/*  
    Copyright (c) 2003-2012 by Marcel Weiher.  All rights reserved.


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
//

#import "MPWIntArray.h"
#import <Foundation/Foundation.h>
#import "DebugMacros.h"

@implementation MPWIntArray

+array
{
	return [[[self alloc] init] autorelease];
}

-initWithCapacity:(unsigned int)newCapacity
{
    if ( self = [super init] ) {
		capacity=newCapacity;
		count=0;
		data=malloc( (capacity+3) * sizeof(int) );
	}
    return self;
}

-init
{
	return [self initWithCapacity:10];
}

-(int)integerAtIndex:(unsigned)index
{
	if ( index < count ) {
		return data[index];
	} else {
		[NSException raise:@"MPWRangeException" format:@"%@ range exception: %d beyond count: %d (capacity: %d)",[self class],index,count,capacity];
		return 0;
	}
}

-(void)_growTo:(unsigned)newCapacity
{
    capacity=capacity*2+2;
	capacity=MAX( capacity, newCapacity );
    if ( data ) {
        data=realloc( data, (capacity+3)*sizeof(int) );
    } else {
        data=calloc( (capacity+3), sizeof(int) );
    }
}


-(void)addIntegers:(int*)intArray count:(unsigned)numIntsToAdd
{
	unsigned newCount=count+numIntsToAdd;
	if ( newCount >= capacity ) {
		[self _growTo:newCount];
	}
	memcpy( data+count, intArray, numIntsToAdd * sizeof(int));
	count=newCount;
}

-(void)addInteger:(int)anInt
{
	[self addIntegers:&anInt count:1];
}

-(void)addObject:anObject
{
	[self addInteger:[anObject intValue]];
}

-(void)replaceIntegerAtIndex:(unsigned)anIndex withInteger:(int)anInt
{
	if ( anIndex < count ) {
		data[anIndex]=anInt;
	} else {
		[NSException raise:@"MPWRangeException" format:@"%@ range exception: %d beyond count: %d (capacity: %d)",[self class],anIndex,count,capacity];
	}
}

-(void)replaceObjectAtIndex:(unsigned)anIndex withObject:anObject
{
	[self replaceIntegerAtIndex:anIndex withInteger:[anObject intValue]];
}

-(void)dealloc
{
	if ( data ) {
		free(data);
	}
	[super dealloc];
}

-(NSUInteger)count
{
	return count;
}

-(void)reset
{
    count=0;
}

-description
{
	if ( [self count] ) {
		NSMutableString *description=[NSMutableString stringWithFormat:@"( %d",[self integerAtIndex:0]];
		for (int i=1;i<[self count];i++) {
			[description appendFormat:@", %d",[self integerAtIndex:i]];
		}
		[description appendString:@")"];
		return description;
	} else {
		return @"( )";
	}
}

@end


@implementation MPWIntArray(testing)

+(void)testArrayAccess
{
	id array=[self array];
	INTEXPECT( [array count], 0 ,@"count of empty array");
	[array addInteger:42];
	INTEXPECT( [array count],1 ,@"count after adding 1 element");
	INTEXPECT( [array integerAtIndex:0],42 ,@"value of element I put");
	[array addObject:@"50"];
	INTEXPECT( [array count],2 ,@"count after adding 2nd element");
	INTEXPECT( [array integerAtIndex:1],50 ,@"value of 2nd element I put");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testArrayAccess",
		nil];
}

@end
