//
//  MPWStreamQLite.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.06.20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MPWPlistStreaming;

@interface MPWStreamQLite : NSObject

@property (nonatomic, strong) id <MPWPlistStreaming> builder;

-(instancetype)initWithPath:(NSString*)dbPath;
-(int)query:(NSString*)sql;
-(int)open;
-(void)close;
-(NSString*)error;


@end

NS_ASSUME_NONNULL_END
