//
//  MPWSFTPStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SSHConnection<NSObject>

@property (nonatomic, strong) NSString *host, *user;

-(int)openConnection;
-store;
-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output;
-run:(NSString*)command;

@end



@interface MPWSFTPStore : MPWAbstractStore

@end

NS_ASSUME_NONNULL_END
