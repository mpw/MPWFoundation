//
//  MPWSocketStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/13/17.
//
//

#import <MPWFoundation/MPWByteStream.h>

@interface MPWSocketStream : MPWStream

-(instancetype)initWithURL:(NSURL*)socketURL;

-(void)open;
-(void)run;

@end
