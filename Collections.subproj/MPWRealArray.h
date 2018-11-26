//
//	MPWRealArray.h
//
//	An array optimized for storing C 'float'
//	numbers, but with a foundation compatible
//	interface (NSArray).
/*
    Copyright (c) 2001-2017 by Marcel Weiher. All rights reserved.

R

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

