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


@class MPWSQLiteWriter,MPWSQLTable;

@interface MPWStreamQLite : NSObject

@property (nonatomic, strong) id <MPWPlistStreaming> builder;
@property (readonly) NSDictionary<NSString*,MPWSQLTable*>* tables;

+(instancetype)open:(NSString*)newpath;
+(instancetype)memory;
-(instancetype)initWithPath:(NSString*)dbPath;
-(int)query:(NSString*)sql;
-(int)open;
-(void)close;
-(NSString*)error;
-(MPWSQLiteWriter*)insert:(NSString*)sql;
-(void*)sqliteDB;
-(void)enableWAL;

@end

@interface MPWStreamQLite(testing)

+_chinookDB;


@end

NS_ASSUME_NONNULL_END


