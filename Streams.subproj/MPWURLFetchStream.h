//
//  MPWURLFetchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWStream.h>

@interface MPWURLFetchStream : MPWStream
{
    NSURLSession *downloader;
}

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) id <Streaming> errorTarget;
@property (assign, readonly)  int inflight;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget;

-(void)setHeaderDict:(NSDictionary *)newHeaders;

-(void)executeRequest:(NSURLRequest*)request;
-(void)executeRequestWithURL:(NSURL *)theURL method:(NSString *)method body:(NSData *)body;

-(void)get:(NSURL*)theURL;
-(void)post:(NSData*)theData toURL:(NSURL *)theURL;
-(void)patch:(NSData*)theData toURL:(NSURL *)theURL;


@end
