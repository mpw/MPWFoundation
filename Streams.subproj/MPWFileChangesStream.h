//
//  MPWFileChangesStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 12.05.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWFileChangesStream : MPWStreamSource

-(instancetype)initWithDirectoryPath:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
