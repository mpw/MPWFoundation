//
//  MPWPListBuilder.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Streaming;

@protocol MPWPlistStreaming<Streaming>

-(void)beginArray;
-(void)endArray;
-(void)beginDictionary;
-(void)endDictionary;
-(void)writeObject:anObject forKey:aKey;

-(void)writeString:aString;
-(void)writeNumber:aNumber;
-(void)writeInteger:(long)number;

-(void)writeKey:aKey;
-(void)pushContainer:anObject;
-(void)pushObject:anObject;

-result;

@end

@class MPWSmallStringTable,MPWObjectCache;

typedef struct {
    __unsafe_unretained id container;
    __unsafe_unretained MPWSmallStringTable *lookup;
    __unsafe_unretained MPWObjectCache *cache;
} CurrentBuildContainer;

@interface MPWPListBuilder : NSObject <MPWPlistStreaming>
{
    id          plist;
    CurrentBuildContainer          containerStack[1000];
    NSString    *key;
    CurrentBuildContainer           *tos;
}

@property (nonatomic, strong)  MPWSmallStringTable  *commonStrings;
@property (nonatomic, assign) long arrayDepth;
@property (nonatomic, assign) long streamingThreshold;
@property (nonatomic, strong) id <Streaming> target;

-result;
+(instancetype)builder;
-(NSString*)key;
-(void)clearResult;

@end
