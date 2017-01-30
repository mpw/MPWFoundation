//
//	MPWRealArray.h
//
//	An array optimized for storing C 'float'
//	numbers, but with a foundation compatible
//	interface (NSArray).
/*
    Copyright (c) 2001-2017 by Marcel Weiher. All rights reserved.

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



//---	inheritance chain

#import "MPWObject.h"


@interface MPWRealArray : MPWObject
{
	NSUInteger	capacity;
	NSUInteger	count;
	float			*floatStart;
}

//---	NSArray compatible


+arrayWithArray:otherArray;
+arrayWithArray:otherArray count:(NSUInteger)count;
+arrayWithArray:otherArray start:(NSUInteger)start count:(NSUInteger)count;

+arrayWithCapacity:(NSUInteger)capacity;
+arrayWithCount:(NSUInteger)newCount;
+arrayWithString:aPropertyList;
+arrayWithReals:(float*)realNums count:(NSUInteger)newCount;

-initWithArray:otherArray;
-initWithArray:otherArray count:(NSUInteger)count;
-initWithArray:otherArray start:(NSUInteger)start count:(NSUInteger)count;
-initWithRealArray:otherArray start:(NSUInteger)start count:(NSUInteger)newCount;
-initWithCapacity:(NSUInteger)capacity;
-initWithCount:(NSUInteger)newCount;
-initWithReals:(float*)realNums count:(NSUInteger)newCount;
-(id)initWithStart:(float)start end:(float)end step:(float)step;
#if !TARGET_OS_IPHONE
-(id)initWithVecStart:(float)start end:(float)end step:(float)step;
#endif

-(NSUInteger)count;
-(void)clear;
-(void)setCapacity:(long)newCapacity;
-(BOOL)isEqual:otherObject;
-(BOOL)matchesStart:otherObject;
-(void)reverse;
-(void)insertValue:(float)aValue betweenEachElementStartingAt:(int)start;
-(void)insertEven:(float)insertValue;
-(void)insertOdd:(float)insertValue;

-objectAtIndex:(NSUInteger)index;
-(void)replaceObjectAtIndex:(NSUInteger)index withObject:newObject;
-(void)addObject:anObject;

//---	faster access to underlying representation


-(void)getReals:(float*)reals length:(long)max;
-(float*)reals;
-(float)realAtIndex:(NSUInteger)index;
-(void)replaceRealAtIndex:(NSUInteger)index withReal:(float)newValue;
-(void)replaceRealsAtIndex:(NSUInteger)index withReals:(float*)newReals count:(NSUInteger)realCount;
-(void)addReal:(float)newValue;
-(void)addReals:(float*)newReals count:(NSUInteger)realCount;
-(void)appendArray:anArray;
-(float)vec_reduce_sum;
-reduce_operator_plus;
-(float)reduce:(float(*)(float,float))reduceFun;

//---	some computation

-interpolate:otherVector into:targetVector weight:(float)weight;
-interpolate:otherVector weight:(float)weight;
-interpolate:otherVector steps:(int)numSteps;


//--	coding etc

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)initWithCoder:(NSCoder *)coder;
-(void)appendContents:aByteStream;

@end

