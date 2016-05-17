//
//  MPWURLFetchStream.m
//  
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"
#import "MPWByteStream.h"


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
        NSURLComponents *components=[NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:YES];
        theURL=[components URLRelativeToURL:self.baseURL];
    }
    return theURL;
    
}

-(void)reportError:(NSError*)error
{
    [self.errorTarget writeObject:error];
}

-(void)fetch:(NSURL*)theURL
{
//    NSLog(@"fetch: %@",theURL);
    theURL=[self resolve:theURL];
    NSLog(@"fetch absolute: %@",[theURL absoluteString]);
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithURL:theURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSLog(@"got back with result %@ for %@",response,theURL);
//        NSLog(@"data: %@",[data stringValue]);
        if ( [response statusCode] >= 400){
            error = [NSError errorWithDomain:@"network" code:[response statusCode] userInfo:@{ @"url": theURL,
                                                                                               @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                                                                                               @"content": [data stringValue]}];
        }
        if (data && !error   ){
            [target writeObject:data];
        } else {
            [self reportError:error];
        }
    }];
    [task resume];

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
    [aStream fetch:self];
}

@end