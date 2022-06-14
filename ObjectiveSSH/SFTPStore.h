//
//  SFTPStore.h
//  ObjectiveSSH
//
//  Created by Marcel Weiher on 12.06.22.
//

#import <MPWFoundation/MPWFoundation.h>

@interface SCPWriter : MPWAbstractStore

@property (nonatomic,assign) int verbosity;
@property (nonatomic,assign) int directoryUMask;
@property (nonatomic,assign) int fileUMask;
@property (nonatomic,strong) NSString *host;
@property (nonatomic,strong) NSString *user;

-(int)openSSH;
-(int)openSFTP;
-(void)disconnect;

@end

