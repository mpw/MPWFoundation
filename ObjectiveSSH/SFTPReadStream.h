//
//  SFTPReadStream.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 14.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SFTPReadStream : MPWStreamSource

-initWithSFTPSession:(void*)session name:(NSString*)name;
-(void)run;


@end

NS_ASSUME_NONNULL_END
