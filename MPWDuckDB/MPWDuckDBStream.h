//
//  MPWDuckDBStream.h
//  MPWDuckDB
//
//  Created by Marcel Weiher on 04.05.25.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MPWPlistStreaming;



@interface MPWDuckDBStream : MPWObject

@property (nonatomic, strong) id <MPWPlistStreaming> builder;


+(instancetype)open:(NSString*)newpath;
-(instancetype)initWithPath:(NSString*)dbPath;


@end

NS_ASSUME_NONNULL_END
