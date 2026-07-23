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

@interface MPWURLStreamingFetchHelper : MPWFilter <NSURLSessionDelegate>

@property (nonatomic, strong)  NSMutableOrderedSet *inflight;

@end



@implementation MPWURLStreamingStream


-(instancetype)initWithBaseURL:(NSURL*)newBaseURL target:aTarget queue:(NSOperationQueue*)targetQueue
{
    MPWURLStreamingFetchHelper *helper = [MPWURLStreamingFetchHelper streamWithTarget:aTarget];
    self.streamingDelegate=helper;
    NSLog(@"init a streaming stream, helper %@",helper);
    NSURLSession *session=[NSURLSession sessionWithConfiguration:[self config]
                                                        delegate:helper
                                                   delegateQueue:targetQueue];
    self=[super initWithBaseURL:newBaseURL target:aTarget session:session];
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
    NSURLSessionResponseDisposition disposition=NSURLSessionResponseAllow;
    NSLog(@"got response: %@",response);
    completionHandler( disposition);
    
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

