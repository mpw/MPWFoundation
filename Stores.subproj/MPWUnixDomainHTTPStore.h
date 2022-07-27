//
//  MPWUnixDomainHTTPStore.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 27.07.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWUnixDomainHTTPStore : MPWAbstractStore

-(instancetype)initWithSocketPath:(NSString*)socketPath;

@property (readonly) NSString *socketPath;

@end

NS_ASSUME_NONNULL_END
