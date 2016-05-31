//
//  MPWURLFetchStream.m
//  
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"
#import "MPWByteStream.h"

@interface MPWURLFetchStream()

@property (assign )  int inflight;

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
    config.HTTPAdditionalHeaders = newHeaderDict;
    
    [self setDownloader:[NSURLSession sessionWithConfiguration:config
                                                      delegate:nil
                                                 delegateQueue:nil]] ;
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnURLFetchStream:);
}

-(void)writeString:(NSString*)aString
{
    [self writeObject:[NSURL URLWithString:aString]];
}

-(NSURL*)resolve:(NSURL*)theURL
{
    if ( self.baseURL) {
        if ( theURL) {
            NSURLComponents *components=[NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:YES];
            theURL=[components URLRelativeToURL:self.baseURL];
        } else {
            theURL=self.baseURL;
        }
    }
    return theURL;
    
}

-(void)reportError:(NSError*)error
{
    [self.errorTarget writeObject:error];
}


-(void)executeRequest:(NSURLRequest*)request
{
    self.inflight++;
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        @try {
            if ( [response respondsToSelector:@selector(statusCode)] && [response statusCode] >= 400){
                error = [NSError errorWithDomain:@"network" code:[response statusCode] userInfo:@{ @"url": request.URL,
                                                                                                   @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                                                                                                   @"content": [data stringValue]}];
            }
            if (data && !error   ){
                [target writeObject:data];
            } else {
                [self reportError:error];
            }
        } @finally {
            self.inflight--;
        }
    }];
    if (!task) {
        [self reportError:[NSError errorWithDomain:@"network-invalid-request" code:1000 userInfo:@{ @"url": request.URL}]];
    }
    [task resume];
    
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
    theURL=[self resolve:theURL];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:theURL];
    request.HTTPMethod = method;
    request.HTTPBody = body;
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
    [aStream get:self];
}

@end