//
//  MPWURLFetchStream.m
//
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) Copyright (c) 2015-2017 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"
#import "MPWByteStream.h"
#import "MPWURLRequest.h"
#import "NSThreadWaiting.h"


@interface MPWURLFetchStream()

@property (nonatomic, strong) NSDictionary *theHeaderDict;
@property (nonatomic, strong) NSMutableSet *inflight;

@end



@implementation MPWURLFetchStream

objectAccessor(NSURLSession, downloader, setDownloader)

CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget session:(NSURLSession*)session)
{
    self=[super initWithTarget:aTarget];
    [self setDownloader:session] ;
    [self setBaseURL:newBaseURL];
    [self setErrorTarget:[MPWByteStream Stderr]];
    [self setDefaultMethod:@"GET"];
    [self setInflight:[NSMutableSet set]];
    self.maxInflight=[self defaultMaxInflight];
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



-(int)inflightCount
{
    return self.inflight.count;
}



-(NSURLSessionConfiguration *)config
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.allowsCellularAccess = YES;
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
    return [s target];
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
    if (self.targetThread) {
        [(NSObject<Streaming> *)self.errorTarget performSelector:@selector(writeObject:)
                                                        onThread:self.targetThread
                                                      withObject:error
                                                   waitUntilDone:NO];
    } else {
        [self.errorTarget writeObject:error];
    }
}


-processResponse:(MPWURLRequest *)response
{
    return [response processed];
}

-(void)removeFromInflight:(MPWURLRequest*)request
{
    @synchronized (self) {
        [self.inflight removeObject:request];
    }
}

-(NSURLRequest*)resolvedRequest:(MPWURLRequest*)request
{
    NSURLRequest *r=request.request;
    NSMutableURLRequest *resolvedRequest=[[r mutableCopy] autorelease];
    resolvedRequest.URL=[self resolve:r.URL];
    return resolvedRequest;
}


- (NSURLSessionTask*)taskForExecutingRequest:(MPWURLRequest*)request
{
    NSParameterAssert( ![request isStreaming]);
    NSURLRequest *resolvedRequest=[self resolvedRequest:request];
//  NSLog(@"url: %@",resolvedRequest.URL);
    NSURLSessionTask *task = [[self downloader] dataTaskWithRequest:resolvedRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @try {
//          NSLog(@"number of inflight requests at top of completion handler: %p %d ",request,[self inflightCount]);
            [self removeFromInflight:request];
//          NSLog(@"number of inflight requests after remove: %p %d ",request,[self inflightCount]);
            request.response=response;
            request.data = data;
            int httpStatusCode=0;
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
                id processed=[self processResponse:request];
//                NSLog(@"will write processed: %@ to %@",processed,target);
                if (self.targetThread) {
                    [target performSelector:@selector(writeObject:)
                                   onThread:self.targetThread
                                 withObject:processed
                              waitUntilDone:NO];
                } else {
                    [target writeObject:processed];
                }
            } else {
//                NSLog(@"Error: %p %@",request,request);
                NSMutableDictionary *userInfoWithRequest = [error.userInfo mutableCopy];
                userInfoWithRequest[@"request"] = request;
                NSError *errorWithRequest = [NSError errorWithDomain:error.domain
                                                                code:error.code
                                                            userInfo:userInfoWithRequest];
                [self reportError:errorWithRequest];
            }
        } @finally {
            [self removeFromInflight:request];
        }
    }];
    return task;
}

-(int)defaultMaxInflight
{
    return 5;
}


-(void)executeRequest:(MPWURLRequest*)request
{
    [request retain];
    int counter=0;
    while ( [self inflightCount] > [self maxInflight] && counter++ < 10) {
        int over=([self inflightCount]-[self maxInflight]);
        [NSThread sleepForTimeInterval:0.1 * (over*over)];
    }
    request.task = [self taskForExecutingRequest:request];
    if (request.task) {
        @synchronized (self) {
            [self.inflight addObject:request];
        }
    } else {
        [self reportError:[NSError errorWithDomain:@"network-invalid-request" code:1000 userInfo:@{ @"url": request.request.URL}]];
    }
    [request.task resume];
}


-(void)awaitResultForSeconds:(NSTimeInterval)numSeconds
{
    [NSThread sleepForTimeInterval:numSeconds orUntilConditionIsMet:^{
        return @([self inflightCount] == 0);
    }];
}

-(void)executeRequestWithURL:(NSURL *)theURL method:(NSString *)method body:(NSData *)body
{
    MPWURLRequest *request=[[[MPWURLRequest alloc] initWithURL:theURL method:method data:body] autorelease];
    [self executeRequest:request];
}


-(void)streamingGet:(NSURL *)theURL body:(NSData *)body
{
    MPWURLRequest *request=[[[MPWURLRequest alloc] initWithURL:theURL method:@"GET" data:body] autorelease];
    request.isStreaming=YES;
    [self executeRequest:request];
}

-(void)get:(NSURL*)theURL
{
    [self executeRequestWithURL:theURL method:@"GET" body:nil];
}

-(void)post:(NSData*)theData toURL:(NSURL *)theURL
{
    [self executeRequestWithURL:theURL method:@"POST" body:theData];
}

-(void)patch:(NSData*)theData toURL:(NSURL *)theURL
{
    [self executeRequestWithURL:theURL method:@"PATCH" body:theData];
}

-(void)delete:(NSURL*)theURL
{
    [self executeRequestWithURL:theURL method:@"DELETE" body:nil];
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
    [_defaultMethod release];
    [(NSObject *)_errorTarget release];
    [_baseURL release];
    [_targetThread release];
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


@implementation MPWURLRequest(streamPosting)

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
    MPWStream *target=[MPWByteStream streamWithTarget:testTarget];
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


