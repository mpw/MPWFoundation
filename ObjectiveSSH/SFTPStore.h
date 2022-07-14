//
//  SFTPStore.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 12.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

@class SSHConnection;

@interface SFTPStore : MPWAbstractStore <MPWStorage>


@property (nonatomic,assign) int verbosity;
@property (nonatomic,assign) int directoryUMask;
@property (nonatomic,assign) int fileUMask;

-(instancetype)initWithSession:(SSHConnection*)newSession;
-(int)openSFTP;
-(void)disconnect;


@end

