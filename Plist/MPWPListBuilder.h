//
//  MPWPListBuilder.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MPWPlistStreaming

-(void)beginArray;
-(void)endArray;
-(void)beginDictionary;
-(void)endDictionary;
-(void)writeKey:aKey;
-(void)writeString:aString;
-(void)writeNumber:aNumber;
-(void)writeObject:anObject forKey:aKey;
-(void)pushContainer:anObject;
-(void)pushObject:anObject;
-(void)writeInteger:(long)number;


-result;

@end

@class MPWSmallStringTable;

@interface MPWPListBuilder : NSObject <MPWPlistStreaming>
{
    id          plist;
    id          containerStack[1000];
    NSString    *key;
    __unsafe_unretained id    *tos;
}

@property (nonatomic, strong)  MPWSmallStringTable  *commonStrings;


-result;
+(instancetype)builder;
-(NSString*)key;

@end
