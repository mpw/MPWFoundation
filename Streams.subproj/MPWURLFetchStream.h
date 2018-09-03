//
//  MPWURLFetchStream.h
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFilter.h>
#import <MPWFoundation/MPWRESTOperation.h>

@class MPWURLCall;

@interface MPWURLFetchStream : MPWFilter


@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) id <Streaming> errorTarget;
@property (nonatomic,assign) MPWRESTVerb defaultMethod;
@property (assign) BOOL  formEncode;
@property (nonatomic, readonly) NSMutableSet *inflight;
@property (nonatomic, readonly) NSURLSession *downloader;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session;

+streamWithBaseURL:(NSURL*)newBaseURL target:aTarget;
-initWithBaseURL:(NSURL*)newBaseURL target:aTarget;

-(void)setHeaderDict:(NSDictionary *)newHeaders;

-(NSURLRequest*)resolvedRequest:(MPWURLCall*)request;
-(void)executeRequest:(MPWURLCall*)request;
-(void)executeRequestWithURL:(NSURL *)theURL method:(MPWRESTVerb)verb  body:(NSData *)body;
-(NSURLSessionConfiguration *)config;


-(void)get:(NSURL*)theURL;
-(void)post:(NSData*)theData toURL:(NSURL *)theURL;
-(void)patch:(NSData*)theData toURL:(NSURL *)theURL;

-(void)writeDictionary:(NSDictionary *)aDictionary;

-(void)awaitResultForSeconds:(NSTimeInterval)seconds;

@end

@interface NSObject(urlFetching)

-(void)writeOnURLFetchStream:(MPWURLFetchStream*)aStream;

@end

