//
//  MPWURLFetchStream.m
//
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"
#import <MPWByteStream.h>
#import "MPWURLCall.h"
#import "NSThreadWaiting.h"
#import "NSStringAdditions.h"
#import "MPWRESTOperation.h"
#import "MPWURLReference.h"

@interface MPWURLFetchStream()

@property (nonatomic, strong) NSDictionary *theHeaderDict;
@property (nonatomic, strong) NSMutableOrderedSet *inflight;
@property (nonatomic, strong) NSURLSession *downloader;

@end



@implementation MPWURLFetchStream


CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session)
{
    self=[super initWithTarget:aTarget];
    [self setDownloader:session] ;
    [self setBaseURL:newBaseURL];
    [self setErrorTarget:[MPWByteStream Stderr]];
    [self setDefaultMethod:MPWRESTVerbGET];
    [self setInflight:[NSMutableOrderedSet orderedSet]];
    return self;
}

CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget)
{
    return [self initWithBaseURL:newBaseURL target:aTarget session:[self defaultURLSession]];
}


-(id)initWithTarget:(id)aTarget
{
    return [self initWithBaseURL:nil target:aTarget];
}



static NSURLSession *_defaultURLSession=nil;

+(NSURLSession*)createDefaultURLSession
{
    return [NSURLSession sharedSession];
}

+(void)setDefaultURLSession:(NSURLSession*)newDefault
{
    [newDefault retain];
    [_defaultURLSession release];
    _defaultURLSession=newDefault;
}

+(NSURLSession*)defaultURLSession
{
    NSURLSession *session=_defaultURLSession;
    if (!session) {
        [self setDefaultURLSession:[self createDefaultURLSession]];
        session=_defaultURLSession;
    }
    return session;
}

-(NSURLSession*)defaultURLSession
{
    return [[self class] defaultURLSession];
}


-(NSURLSessionConfiguration *)config
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
#ifndef GNUSTEP
    // TODO GNUStep has no allowsCellularAccess property defined
    sessionConfiguration.allowsCellularAccess = YES;
#endif    
    sessionConfiguration.HTTPShouldUsePipelining = YES;
    sessionConfiguration.HTTPShouldSetCookies = YES;
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    sessionConfiguration.URLCache = nil;
    return sessionConfiguration;
}

//--- legacy

-(void)setHeaderDict:(NSDictionary *)newHeaderDict
{
    NSURLSessionConfiguration *config=[self config];
    NSDictionary *oldDict=self.theHeaderDict;
    
    if ( ![oldDict isEqual:newHeaderDict]) {
        self.theHeaderDict = newHeaderDict;
        config.HTTPAdditionalHeaders = newHeaderDict;
        
        [self setDownloader:[NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:nil]] ;
    }
}

-(SEL)streamWriterMessage
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    return @selector(writeOnURLFetchStream:);
#pragma clang diagnostic pop
}

-(void)writeString:(NSString*)aString
{
    [self writeObject:[NSURL URLWithString:aString]];
}



-(NSData *)formEncodeDictionary:(NSDictionary*)aDict
{
    MPWByteStream *s=[MPWByteStream stream];
    BOOL first=YES;
    //    NSLog(@"should encode dictionary: %@",aDict);
    for ( NSString *key in aDict.allKeys ) {
        [s printFormat:@"%@%@=%@",first?@"":@"&", key,aDict[key]];
        first=NO;
    }
    //    NSLog(@"encoded dict: '%@'",[[s target] stringValue]);
    return (NSData*)[s target];
}




-(NSData *)jsonEncodeDictionary:(NSDictionary *)aDictionary
{
    return [NSJSONSerialization dataWithJSONObject:aDictionary options:0 error:nil];
}

-(NSData *)serializeDictionary:(NSDictionary *)aDictionary
{
    if ( self.formEncode) {
        return [self formEncodeDictionary:aDictionary];
    } else {
        return [self jsonEncodeDictionary:aDictionary];
    }
}


-(void)writeDictionary:(NSDictionary *)aDictionary
{
    [self writeObject:[self serializeDictionary:aDictionary]];
}


-(NSURL*)resolve:(NSURL*)theURL
{
    //    NSLog(@"baseURL URL:\n%@\n",[self.baseURL absoluteString]);
    //    NSLog(@"relative URL:\n%@\n",[theURL absoluteString]);
    if ( self.baseURL) {
        if ( theURL) {
            NSURLComponents *components=[NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:YES];
            theURL=[components URLRelativeToURL:self.baseURL];
        } else {
            theURL=self.baseURL;
        }
    }
    //    NSLog(@"%@ resolved URL:\n%@\n",self,[theURL absoluteString]);
    return theURL;
}

-(void)reportError:(NSError*)error
{
    [self.errorTarget writeObject:error];
}


-processResponse:(MPWURLCall *)response
{
    return [response processed];
}

-(void)removeFromInflight:(MPWURLCall*)request
{
    @synchronized (self) {
        [self.inflight removeObject:request];
    }
}

-(NSURLRequest*)resolvedRequest:(MPWURLCall*)request
{
    NSURLRequest *r=request.request;
    NSMutableURLRequest *resolvedRequest=[[r mutableCopy] autorelease];
    resolvedRequest.URL=[self resolve:r.URL];
    return resolvedRequest;
}


- (NSURLSessionTask*)taskForExecutingRequest:(MPWURLCall*)request
{
    NSParameterAssert( ![request isStreaming]);
    NSURLRequest *resolvedRequest=[self resolvedRequest:request];
//  NSLog(@"url: %@",resolvedRequest.URL);
    NSURLSessionTask *task = [[self downloader] dataTaskWithRequest:resolvedRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @try {
            [self removeFromInflight:request];
            request.response=response;
            request.data = data;
            long httpStatusCode=0;
            if ( [response respondsToSelector:@selector(statusCode)] ) {
                httpStatusCode=[(NSHTTPURLResponse*)response statusCode];
            }
//            NSLog(@"data: %@",[data stringValue]);
            if ( httpStatusCode >= 400){
                NSDictionary *userInfo=
                @{ @"url": resolvedRequest.URL,
                   @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                   @"content": data ? [data stringValue] : @""
                   };
                error = [NSError errorWithDomain:@"network" code:httpStatusCode userInfo:userInfo];
            }
            if (data && !error   ){
                FORWARD([self processResponse:request]);
            } else {
//                NSLog(@"Error: %p %@",request,request);
                NSMutableDictionary *userInfoWithRequest = [[error.userInfo mutableCopy] autorelease];
                userInfoWithRequest[@"request"] = request;
                NSError *errorWithRequest = [NSError errorWithDomain:error.domain
                                                                code:error.code
                                                            userInfo:userInfoWithRequest];
                request.error = error;
                [self reportError:errorWithRequest];
            }
        } @finally {
            [self removeFromInflight:request];
        }
    }];
    return task;
}


-(void)enqueueRequest:(MPWURLCall*)request
{
    [request retain];
    request.task = [self taskForExecutingRequest:request];
    if (request.task) {
        @synchronized (self) {
            [self.inflight addObject:request];
        }
    } else {
        [self reportError:[NSError errorWithDomain:@"network-invalid-request" code:1000 userInfo:@{ @"url": request.request.URL}]];
    }
}

-(MPWURLCall*)lastRequest
{
    return self.inflight.lastObject;
}

-(void)run
{
    [[self lastRequest].task resume];
}

-(void)do:aBlock
{
    [super do:aBlock];
    [self run];
}

-(void)executeRequest:(MPWURLCall*)request
{
    [self enqueueRequest:request];
    [self run];
}

-(int)inflightCount
{
    return (int)[self.inflight count];
}

-(void)awaitResultForSeconds:(NSTimeInterval)numSeconds
{
    [NSThread sleepForTimeInterval:numSeconds orUntilConditionIsMet:^{
        return @([self inflightCount] == 0);
    }];
}

-(void)executeRequestWithURL:(NSURL *)theURL method:(MPWRESTVerb)verb body:(NSData *)body
{
    MPWURLReference *ref=[MPWURLReference referenceWithURL:theURL];
    MPWRESTOperation<MPWURLReference*>* op=[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.isStreaming=NO;
    [self executeRequest:request];
}


-(void)get:(NSURL*)theURL
{
    [self executeRequestWithURL:theURL method:MPWRESTVerbGET body:nil];
}

-(void)post:(NSData*)theData toURL:(NSURL *)theURL
{
    [self executeRequestWithURL:theURL method:MPWRESTVerbPOST body:theData];
}

-(void)patch:(NSData*)theData toURL:(NSURL *)theURL
{
    [self executeRequestWithURL:theURL method:MPWRESTVerbPATCH body:theData];
}

-(void)put:(NSData*)theData toURL:(NSURL *)theURL
{
    [self executeRequestWithURL:theURL method:MPWRESTVerbPUT body:theData];
}

-(void)delete:(NSURL*)theURL
{
    [self executeRequestWithURL:theURL method:MPWRESTVerbDELETE body:nil];
}

-(void)writeData:(NSData *)d
{
    [self patch:d toURL:nil];
}

-(void)writeNSURL:(NSURL*)url
{
    [self executeRequestWithURL:url method:self.defaultMethod body:nil];
}


-(void)dealloc
{
//    NSLog(@"deallocating MPWURLFetchStream %p",self);
    [_inflight release];
    [_theHeaderDict release];
    [(NSObject *)_errorTarget release];
    [_baseURL release];
    [_downloader release];
    [super dealloc];
}

@end

@implementation NSString(writeOnURLFetchStream)

-(void)writeOnURLFetchStream:(MPWURLFetchStream*)aStream
{
    [aStream writeString:self];
}

@end

@implementation NSURL(writeOnURLFetchStream)

-(void)writeOnURLFetchStream:(MPWURLFetchStream*)aStream
{
    [aStream writeNSURL:self];
}

@end


@implementation NSDictionary(streamPosting)

-(void)writeOnURLFetchStream:aStream
{
    [aStream writeDictionary:self];
}

@end



@implementation NSData(streamPosting)

-(void)writeOnURLFetchStream:(MPWURLFetchStream *)aStream
{
    [aStream writeData:self];
}

@end


@implementation MPWURLCall(streamPosting)

-(void)writeOnURLFetchStream:aStream
{
    [aStream executeRequest:self];
}

@end

#import "DebugMacros.h"

@implementation MPWURLFetchStream(testing)

+(void)testCanHandleDataStreamingResponse
{
    NSMutableString *testTarget=[NSMutableString string];
    NSURL *testURL=[[NSBundle bundleForClass:self] URLForResource:@"ResourceTest" withExtension:nil];
    MPWWriteStream *target=[MPWByteStream streamWithTarget:testTarget];
    MPWURLFetchStream* stream=[self streamWithTarget:target];
    [stream get:testURL];
    [stream awaitResultForSeconds:1];
    IDEXPECT( testTarget, @"This is a simple resource",@"should have written");
    
}


+testSelectors
{
    return
    @[
      @"testCanHandleDataStreamingResponse",
      ];
}

@end


