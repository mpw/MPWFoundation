//
//  MPWURLFetchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWURLFetchStream : MPWStream
{
    NSURLSession *downloader;
}

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) id <Streaming> errorTarget;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget;

-(void)setHeaderDict:(NSDictionary *)newHeaders;

@end
