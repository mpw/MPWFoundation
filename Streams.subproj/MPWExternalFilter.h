//
//  MPWExternalFilter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/29/17.
//
//

#import <MPWFoundation/MPWStream.h>

@interface MPWExternalFilter : MPWStream
+(instancetype)filterWithCommandString:(NSString *)command;

@end
