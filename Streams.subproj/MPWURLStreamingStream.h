//
//  MPWURLStreamingStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/17.
//
//

#import <MPWFoundation/MPWURLFetchStream.h>

@class MPWURLStreamingFetchHelper;

@interface MPWURLStreamingStream : MPWURLFetchStream

@property (nonatomic, strong) MPWURLStreamingFetchHelper *streamingDelegate;


@end
