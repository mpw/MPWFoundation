//
//  MPWURLStreamingStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/17.
//
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWURLStreamingFetchHelper;

@interface MPWURLStreamingStream : MPWURLFetchStream

@property (nonatomic, strong) MPWURLStreamingFetchHelper *streamingDelegate;


@end
