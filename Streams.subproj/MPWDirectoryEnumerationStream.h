//
//  MPWDirectoryEnumerationStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.05.25.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWDirectoryEnumerationStream : MPWStreamSource

-(instancetype)initWithPath:(NSString*)aPath;

@end

NS_ASSUME_NONNULL_END
