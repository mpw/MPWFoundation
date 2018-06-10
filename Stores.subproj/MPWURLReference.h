//
//  MPWURLReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWURLReference : MPWReference <MPWReferencing>

@property (nonatomic, readonly, strong) NSURL *URL;

@end
