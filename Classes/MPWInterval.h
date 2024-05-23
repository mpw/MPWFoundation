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



-initFrom:newFrom to:newTo;
-objectEnumerator;
-(void)do:aBlock;
-(id)add:aNumber;
-(id)sub:aNumber;
-(id)mul:aNumber;
-(id)div:aNumber;
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
