//
//  MPWStreamableBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.07.22.
//

#import <MPWFoundation/MPWBinding.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStreamSource;

@interface MPWStreamableBinding : MPWBinding

-source;
-(MPWByteStream*)writeStream;
-(MPWStreamSource*)lines;
-(MPWStreamSource*)linesAfter:(int)numToSkip;

@end

NS_ASSUME_NONNULL_END
