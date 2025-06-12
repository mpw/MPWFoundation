//
//  MPWInterval.h
//  MPWTalk
//
//  Created by Marcel Weiher on 26/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPWInterval : NSArray {
	Class numberClass;
}


+(instancetype)intervalFrom:newFrom to:newTo;
+(instancetype)intervalFrom:newFrom to:newTo step:newStep;
+(instancetype)intervalFromInt:(long)newFrom toInt:(long)newTo step:(long)newStep;
+(instancetype)intervalFromInt:(long)newFrom toInt:(long)newTo;

-(instancetype)initFrom:newFrom to:newTo;
-objectEnumerator;
-collect:aBlock;
-(void)do:aBlock;
-(instancetype)add:aNumber;
-(instancetype)sub:aNumber;
-(instancetype)mul:aNumber;
-(instancetype)div:aNumber;
-(NSNumber*)random;

@end

@interface MPWDoubleInterval : MPWInterval
{
    
}


@end

@interface MPWLongInterval : MPWInterval
{
    NSRange range;
}

+intervalFromInt:(long)newFrom toInt:(long)newTo;
+intervalFrom:newFrom to:newTo step:newStep;

+intervalFrom:newFrom to:newTo;
-initFromInt:(long)newFrom toInt:(long)newTo;

@property (assign) long from,to,step;

-(NSRange)asNSRange;
-(NSRange)rangeValue;
-(NSRangePointer)rangePointer;

@end

@interface NSNumber(intervals)

-(MPWInterval*)to:(NSNumber*)other;
-(MPWInterval*)to:(NSNumber*)otherNumber by:(NSNumber*)stepNumber;

@end
