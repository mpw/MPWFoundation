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

@interface MPWURLFetchStream()

@property (assign )  int inflight;
@property (nonatomic, strong) NSDictionary *theHeaderDict;

@end


@implementation MPWURLFetchStream

objectAccessor(NSURLSession, downloader, setDownloader)

CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget)
{
    self=[super initWithTarget:aTarget];
    [self setDownloader:[NSURLSession sessionWithConfiguration:[self config]
                                                      delegate:nil
                                                  delegateQueue:nil]] ;
    [self setBaseURL:newBaseURL];
    [self setErrorTarget:[MPWByteStream Stderr]];
    [self setDefaultMethod:@"GET"];
    self.inflight=0;
    return self;
}

-(id)initWithTarget:(id)aTarget
{
    return [self initWithBaseURL:nil target:target];
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
    NSURLRequest *r=request.request;
    NSMutableURLRequest *resolvedRequest=[r mutableCopy];
    resolvedRequest.URL=[self resolve:r.URL];
    [request retain];
    [resolvedRequest retain];
//    NSLog(@"executeRequest: %@",request);
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithRequest:resolvedRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @try {
            request.response=response;
            request.data = data;
            if ( [response respondsToSelector:@selector(statusCode)] && [response statusCode] >= 400){
                error = [NSError errorWithDomain:@"network" code:[response statusCode] userInfo:@{ @"url": resolvedRequest.URL,
                                                                                                   @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                                                                                                   @"content": [data stringValue]}];
            }
            request.error = error;
            if (data && !error   ){
//                NSLog(@"Success: %@",request);
                [target writeObject:[self processResponse:request]];
            } else {
//                NSLog(@"Error: %@",request);
                [self reportError:request];
            }
        } @finally {
            self.inflight--;
        }
    }];
    if (!task) {
        self.inflight--;
        [self reportError:[NSError errorWithDomain:@"network-invalid-request" code:1000 userInfo:@{ @"url": request.request.URL}]];
    }
    [task resume];
    
}

-(void)executeNSURLRequest:(NSURLRequest*)nsrequest
{
    MPWURLRequest *urlrequest=[[MPWURLRequest new] autorelease];
    urlrequest.request=nsrequest;
    [self executeRequest:urlrequest];
}

#define CHECKS_PER_SECOND 100

-(void)awaitResultForSeconds:(int)numSeconds
{
    [NSThread sleepForTimeInterval:numSeconds orUntilConditionIsMet:^{
        [self inflight] == 0;
    }];
}

-(void)executeRequestWithURL:(NSURL *)theURL method:(NSString *)method body:(NSData *)body
{
    MPWURLRequest *request=[[[MPWURLRequest alloc] initWithURL:theURL method:method data:body] autorelease];
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



