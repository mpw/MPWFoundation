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
    NSURLSession *session=[NSURLSession sessionWithConfiguration:[self config]
                                                        delegate:helper
                                                   delegateQueue:targetQueue];
    self.streamingDelegate=helper;
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
    return [[self downloader] dataTaskWithRequest: [self resolvedRequest:request]];
}

-(void)streamingGet:(NSURL *)theURL
{
    MPWURI *ref=[MPWURI referenceWithURL:theURL];
    MPWRESTOperation<MPWURI*>* op=[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.isStreaming=YES;
    [self executeRequest:request];
}

-(void)setTarget:(id)newVar
{
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
    FORWARD(data);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
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

