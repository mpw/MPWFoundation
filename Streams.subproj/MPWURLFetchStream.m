//
//  MPWURLFetchStream.m
//  
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"
#import "MPWByteStream.h"
#import "MPWURLRequest.h"
#import "NSThreadWaiting.h"

@interface MPWURLFetchStream() <NSURLSessionDelegate>

@property (assign )  int inflight;
@property (nonatomic, strong) NSDictionary *theHeaderDict;

@end


@implementation MPWURLFetchStream

objectAccessor(NSURLSession, downloader, setDownloader)

CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget)
{
    self=[super initWithTarget:aTarget];
    [self setDownloader:[NSURLSession sessionWithConfiguration:[self config]
                                                      delegate:self
                                                  delegateQueue:nil]] ;
    [self setBaseURL:newBaseURL];
    [self setErrorTarget:[MPWByteStream Stderr]];
    [self setDefaultMethod:@"GET"];
    self.inflight=0;
    return self;
}

-(id)initWithTarget:(id)aTarget
{
    return [self initWithBaseURL:nil target:aTarget];
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
    return @selector(writeOnURLFetchStream:);
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
    [self.errorTarget writeObject:error];
}


-processResponse:(MPWURLRequest *)response
{
    return [response processed];
}

-(void)executeRequest:(MPWURLRequest*)request
{
    self.inflight++;
    BOOL shouldStream=NO;
    NSURLRequest *r=request.request;
    NSMutableURLRequest *resolvedRequest=[[r mutableCopy] autorelease];
    resolvedRequest.URL=[self resolve:r.URL];
    [request retain];
    shouldStream = [request isStreaming];
//    NSLog(@"executeRequest: %@",request);
    NSURLSessionDataTask *task=nil;
    if ( shouldStream ) {
        task = [[self downloader] dataTaskWithRequest: resolvedRequest];
//        NSLog(@"task: %@",task);
    } else {
        task = [[self downloader] dataTaskWithRequest:resolvedRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            @try {
                request.response=response;
                request.data = data;
                int httpStatusCode=0;
                if ( [response respondsToSelector:@selector(statusCode)] ) {
                    httpStatusCode=[(NSHTTPURLResponse*)response statusCode];
                }
                NSLog(@"data: %@",[data stringValue]);
                if ( httpStatusCode >= 400){
                    error = [NSError errorWithDomain:@"network" code:httpStatusCode userInfo:@{ @"url": resolvedRequest.URL,
                                                                                                @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                                                                                                @"content": [data stringValue]}];
                }
                request.error = error;
                if (data && !error   ){
                    NSLog(@"Success: %@",request);
                    [target writeObject:[self processResponse:request]];
                } else {
                    NSLog(@"Error: %@",request);
                    [self reportError:request];
                }
            } @finally {
                self.inflight--;
            }
        }];
    }
    if (!task) {
        self.inflight--;
        [self reportError:[NSError errorWithDomain:@"network-invalid-request" code:1000 userInfo:@{ @"url": request.request.URL}]];
    }
    [task resume];
    
}


#define CHECKS_PER_SECOND 100

-(void)awaitResultForSeconds:(NSTimeInterval)numSeconds
{
    [NSThread sleepForTimeInterval:numSeconds orUntilConditionIsMet:^{
        return @([self inflight] == 0);
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

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [target writeObject:data];
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

-(void)writeOnURLFetchStream:aStream
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
    [stream streamingGet:testURL body:nil];
    [stream awaitResultForSeconds:0.01];
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
