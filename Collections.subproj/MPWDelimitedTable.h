//
//  MPWDelimitedTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/22/13.
//
//

#import <Foundation/Foundation.h>

@class MPWIntArray,MPWObjectCache;

@interface MPWDelimitedTable : NSObject
{
    NSData  *data;
    const char *bytes;
    NSArray *headerKeys;
    NSString *fieldDelimiter;
    MPWIntArray *lineOffsets;
    int eolLength;
    char fieldDelimiterBytes[20];
    int  fieldDelimiterLength;
    MPWObjectCache *subdatas;
    NSArray   *keysOfInterest;
    MPWIntArray *indexesOfInterest;
}

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

