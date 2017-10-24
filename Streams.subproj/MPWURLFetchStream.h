//
//  MPWURLFetchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWStream.h>

@class MPWURLRequest;

@interface MPWURLFetchStream : MPWStream
{
    NSURLSession *downloader;
}

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) id <Streaming> errorTarget;
@property (assign, readonly)  int inflightCount;
@property (nonatomic,strong) NSString *defaultMethod;
@property (assign) BOOL  formEncode;
@property (nonatomic, readonly) NSMutableSet *inflight;
@property (nonatomic, readonly) NSURLSession *downloader;
@property (assign)  int maxInflight;
@property (nonatomic, strong) NSThread *targetThread;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget;

-(void)setHeaderDict:(NSDictionary *)newHeaders;

-(NSURLRequest*)resolvedRequest:(MPWURLRequest*)request;
-(void)executeRequest:(MPWURLRequest*)request;
-(void)executeRequestWithURL:(NSURL *)theURL method:(NSString *)method body:(NSData *)body;
-(NSURLSessionConfiguration *)config;


-(void)get:(NSURL*)theURL;
-(void)post:(NSData*)theData toURL:(NSURL *)theURL;
-(void)patch:(NSData*)theData toURL:(NSURL *)theURL;

-(void)writeDictionary:(NSDictionary *)aDictionary;

-(void)awaitResultForSeconds:(NSTimeInterval)seconds;

@end
