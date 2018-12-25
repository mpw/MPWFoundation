//
//  MPWInterval.h
//  MPWTalk
//
//  Created by Marcel Weiher on 26/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPWInterval : NSArray {
	NSRange range;
	long	step;
	Class numberClass;
}

@property (assign) long from,to,step;


+intervalFromInt:(long)newFrom toInt:(long)newTo;
+intervalFrom:newFrom to:newTo step:newStep;

+intervalFrom:newFrom to:newTo;
-initFromInt:(long)newFrom toInt:(long)newTo;
-initFrom:newFrom to:newTo;
-objectEnumerator;
-(NSRange)asNSRange;
-(NSRange)rangeValue;
-(NSRangePointer)rangePointer;
-(void)do:aBlock;
-(id)add:aNumber;
-(id)sub:aNumber;
-(id)mul:aNumber;
-(id)div:aNumber;

@end
