//
//  MPWURLReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWURLReference : MPWReference <MPWReferencing,MPWReferenceCreation>

@property (nonatomic, readonly, strong) NSURL *URL;
@property (nonatomic,assign) int port;

+(instancetype)referenceWithURL:(NSURL*)components;

@end
