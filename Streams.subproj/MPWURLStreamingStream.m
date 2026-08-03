//
//  MPWURLStreamingStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/17.
//
//

#import "MPWURLStreamingStream.h"
#import <MPWByteStream.h>
#import "MPWURLCall.h"
#import "MPWURI.h"
#import "MPWRESTOperation.h"

@interface MPWURLStreamingFetchHelper : MPWFilter <NSURLSessionTaskDelegate>

@property (nonatomic, strong)  NSMutableOrderedSet *inflight;

@end

@interface MPWURLStreamingStream ()

@property (nonatomic, strong) NSDictionary *streamingHeaderDict;

@end



@implementation MPWURLStreamingStream


-(instancetype)initWithBaseURL:(NSURL*)newBaseURL target:aTarget queue:(NSOperationQueue*)targetQueue
{
    MPWURLStreamingFetchHelper *helper = [MPWURLStreamingFetchHelper streamWithTarget:aTarget];
    NSURLSessionConfiguration *configuration=[self config];
    // Streaming responses can legitimately run for a long time.  This timeout is
    // the maximum idle interval between packets, not the total response duration.
    configuration.timeoutIntervalForRequest=60 * 60;
    configuration.timeoutIntervalForResource=24 * 60 * 60;
    NSURLSession *session=[NSURLSession sessionWithConfiguration:configuration
    self.streamingDelegate=helper;
    NSLog(@"init a streaming stream, helper %@",helper);
                                                        delegate:helper
                                                   delegateQueue:targetQueue];
    self=[super initWithBaseURL:newBaseURL target:aTarget session:session];
    self.streamingDelegate=helper;
    self.streamingDelegate.inflight = self.inflight;
    return self;
}

-(instancetype)initWithBaseURL:(NSURL*)newBaseURL target:aTarget
{
    return [self initWithBaseURL:newBaseURL target:aTarget queue:nil];
}


- (NSURLSessionTask*)taskForExecutingRequest:(MPWURLCall*)request
{
    NSParameterAssert( [request isStreaming]);
    NSURLRequest *resolvedRequest=[self resolvedRequest:request];
    NSLog(@"executing url: %@",resolvedRequest.URL);
    NSLog(@"executing verb: %@",resolvedRequest.HTTPMethod);
    NSLog(@"executing data: '%@'",[resolvedRequest.HTTPBody stringValue]);
    NSLog(@"ask downloader %@ to create task: %@",[self downloader],request);
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithRequest: resolvedRequest];
    task.delegate = self.streamingDelegate;
    NSLog(@"streamingDelegat: %@",self.streamingDelegate);
    [task resume];
    NSLog(@"task: %@",task);
    return task;
}

-(void)setHeaderDict:(NSDictionary *)newHeaderDict
{
    // MPWURLFetchStream's implementation replaces the session with one that has
    // no delegate.  That turns a streaming data task back into a buffered one.
    self.streamingHeaderDict=newHeaderDict;
}

-(NSURLRequest*)resolvedRequest:(MPWURLCall*)request
{
    NSMutableURLRequest *resolved=[[super resolvedRequest:request] mutableCopy];
    [resolved setAllHTTPHeaderFields:self.streamingHeaderDict];
    return [resolved autorelease];
}

-(void)executeRequestWithURL:(NSURL *)theURL method:(MPWRESTVerb)verb body:(NSData *)body
{
    MPWURI *ref=[MPWURI referenceWithURL:theURL];
    MPWRESTOperation<MPWURI*>* op=[MPWRESTOperation operationWithReference:ref verb:verb];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.bodyData=body;
    request.isStreaming=YES;
    [self executeRequest:request];
}

-(void)streamingGet:(NSURL *)theURL
{
    MPWURI *ref=[MPWURI referenceWithURL:theURL];
    MPWRESTOperation<MPWURI*>* op=[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.isStreaming=YES;
    NSLog(@"enqueue request");
    [self executeRequest:request];
}

-(void)get:(NSURL *)theURL
{
    return [self streamingGet:theURL];
}



-(void)streamingPost:(NSURL *)theURL data:(NSData*)data
{
    MPWURI *ref=[MPWURI referenceWithURL:theURL];
    MPWRESTOperation<MPWURI*>* op=[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbPOST];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.bodyData = data;
    request.isStreaming=YES;
    NSLog(@"enqueue request");
    [self executeRequest:request];
}

-(void)post:(NSData *)theData toURL:(NSURL *)theURL
{
    [self streamingPost:theURL data:theData];
}

-(void)setTarget:(id)newVar
{
    NSLog(@"streaming stream target: %@",newVar);
    [super setTarget:newVar];
    [self.streamingDelegate setTarget:newVar];
}



-(void)dealloc
{
    [_streamingHeaderDict release];
    [_streamingDelegate release];
    [super dealloc];
}


@end


@implementation MPWURLStreamingFetchHelper

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSLog(@"received some data");
    FORWARD(data);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSHTTPURLResponse *)response
                                  completionHandler:(void (NS_SWIFT_SENDABLE ^)(NSURLSessionResponseDisposition disposition))completionHandler;
{
    NSURLSessionResponseDisposition disposition=NSURLSessionResponseBecomeStream;
    NSLog(@"got response: %@",response);
    completionHandler( disposition);
    
}


-(void)streamMore:(NSURLSessionStreamTask *) streamTask
{
    NSLog(@"stream more");
    [streamTask readDataOfMinLength:50 maxLength:2000 timeout:60 completionHandler:^(NSData * _Nullable_result data, BOOL atEOF, NSError * _Nullable error){
        if ( data.length) {
            NSLog(@"got data");
            FORWARD(data);
        }
        if (!atEOF && data.length > 0) {
            NSLog(@"not at EOF");
            [self streamMore:streamTask];
        } else {
            NSLog(@"at EOF (eof: %d length: %ld)",atEOF,(long)data.length);
        }
    }];
    
}

- (void) URLSession:(NSURLSession *) session
           dataTask:(NSURLSessionDataTask *) dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *) streamTask
{
    NSLog(@"task changed to streaming task");
    NSLog(@"original: %@",dataTask);
    NSLog(@"streaming: %@",streamTask);
    NSLog(@"task changed to streaming task");
    streamTask.delegate = self;
    [streamTask resume];
    [self streamMore:streamTask];
    NSLog(@"resumed streaming: %@",streamTask);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    NSLog(@"did complete");
    @synchronized (self) {
        //  a streaming fetchstream can only have one in progress
        //  and we don't have accesss to the MPWCall here.
        [self.inflight removeAllObjects];
    }
    if ( error ){
        [self reportError:error];
    }
    [(MPWFilter*)self.target close];
}


-(void)dealloc
{
    [_inflight release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWURLStreamingStream(testing)

+(void)testCanHandleDataStreamingResponse
{
    NSMutableString *testTarget=[NSMutableString string];
    NSURL *testURL=[[NSBundle bundleForClass:self] URLForResource:@"ResourceTest" withExtension:nil];
    MPWWriteStream *target=[MPWByteStream streamWithTarget:testTarget];
    MPWURLStreamingStream* stream=[self streamWithTarget:target];
    [stream streamingGet:testURL];
    [stream awaitResultForSeconds:0.5];
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
