//
//  MPWMASONParser.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/29/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWXmlAppleProplistReader.h"

@class MPWSmallStringTable;
@protocol MPWPlistStreaming;

@interface MPWMASONParser : MPWXmlAppleProplistReader {
	BOOL inDict;
	BOOL inArray;
	MPWSmallStringTable *commonStrings;
}

@property (nonatomic, strong) id <MPWPlistStreaming> builder;

-(void)setFrequentStrings:(NSArray*)strings;

@end
