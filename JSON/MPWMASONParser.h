//
//  MPWMASONParser.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/29/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWXmlAppleProplistReader.h>

@class MPWSmallStringTable;
@protocol MPWPlistStreaming;

@interface MPWMASONParser : MPWXmlAppleProplistReader {
	MPWSmallStringTable *commonStrings;
}

@property (nonatomic, strong) id <MPWPlistStreaming> builder;
@property (nonatomic, strong) MPWObjectCache *stringCache;


-(void)setFrequentStrings:(NSArray*)strings;
-(instancetype)initWithClass:(Class)classToDecode;
-(instancetype)initWithBuilder:aBuilder;

@end
