//
//  MPWDelimitedTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import <MPWFoundation/MPWTable.h>

@protocol MPWPlistStreaming;

@interface MPWDelimitedTable : MPWTable


-initWithData:(NSData*)newTableData delimiter:(NSString*)newFieldDelimiter;
-initWithTabSeparatedData:(NSData*)newTableData;
-initWithCommaSeparatedData:(NSData*)newTableData;
-(NSUInteger)count;
-(NSArray*)headerKeys;
-(NSDictionary*)dictionaryAtIndex:(int)anIndex;

-(void)do:(void(^)(NSDictionary* theDict, int anIndex))block;
-(NSArray*)collect:(id(^)(id theDict))block;
-(NSArray*)parcollect:(id(^)(id theDict))block;
-(void)pardo:(void(^)(NSDictionary* theDict, int anIndex))block;
-(void)setKeysOfInterest:(NSArray*)keys;


-(NSDictionary*)slowDictionaryAtIndex:(int)anIndex;
-(void)writeOnBuilder:(id <MPWPlistStreaming>)builder;


@end

