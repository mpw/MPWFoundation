//
//  MPWStreamQLite.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.06.20.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/MPWFlattenStream.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MPWPlistStreaming;

@interface MPWSQLiteWriter : MPWFlattenStream
-(void)beginArray;
-(void)endArray;

@end



@interface MPWStreamQLite : NSObject

@property (nonatomic, strong) id <MPWPlistStreaming> builder;

+(instancetype)open:(NSString*)newpath;
+(instancetype)memory;
-(instancetype)initWithPath:(NSString*)dbPath;
-(int)query:(NSString*)sql;
-(int)open;
-(void)close;
-(NSString*)error;
-(MPWSQLiteWriter*)insert:(NSString*)sql;

@end

NS_ASSUME_NONNULL_END


