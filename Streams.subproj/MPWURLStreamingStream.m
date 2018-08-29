//
//  MPWURLStreamingStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/14/17.
//
//

#import "MPWURLStreamingStream.h"
#import "MPWByteStream.h"
#import "MPWURLCall.h"
#import "MPWURLReference.h"
#import "MPWRESTOperation.h"

@interface MPWURLStreamingFetchHelper : MPWStream <NSURLSessionDelegate>

@property (nonatomic, strong)  NSMutableSet *inflight;

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
    NSURLComponents *comps=[NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:YES];
    MPWURLReference *ref=[MPWURLReference referenceWithURLComponents:comps];
    MPWRESTOperation<MPWURLReference*>* op=[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET];
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
    [target writeObject:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    @synchronized (self) {
        [self.inflight removeObject:task];
    }
    if ( error ){
        [self reportError:error];
    }
    [target close];
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
    MPWStream *target=[MPWByteStream streamWithTarget:testTarget];
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

