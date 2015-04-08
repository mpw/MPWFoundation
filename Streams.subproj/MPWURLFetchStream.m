//
//  MPWURLFetchStream.m
//  StackOverflow
//
//  Created by Marcel Weiher on 3/31/15.
//  Copyright (c) 2015 Marcel Weiher. All rights reserved.
//

#import "MPWURLFetchStream.h"

@implementation MPWURLFetchStream

objectAccessor(NSURL, baseURL, setBaseURL)
objectAccessor(NSURLSession, downloader, setDownloader)

CONVENIENCEANDINIT(stream, WithBaseURL:(NSURL*)newBaseURL target:aTarget)
{
    self=[super initWithTarget:aTarget];
    [self setDownloader:[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                      delegate:nil
                                                  delegateQueue:nil]] ;
    [self setBaseURL:newBaseURL];
    return self;
}

-(id)initWithTarget:(id)aTarget
{
    return [self initWithBaseURL:nil target:target];
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnURLFetchStream:);
}

-(void)writeString:(NSString*)aString
{
//    NSLog(@"writeString: %@",aString);
    [self writeObject:[NSURL URLWithString:aString]];
}

-(NSURL*)resolve:(NSURL*)theURL
{
    if ( baseURL) {
        NSURLComponents *components=[NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:YES];
        theURL=[components URLRelativeToURL:baseURL];
    }
    return theURL;
    
}

-(void)reportError:(NSError*)error
{
    NSLog(@"error: %@",error);
}

-(void)fetch:(NSURL*)theURL
{
//    NSLog(@"fetch: %@",theURL);
    theURL=[self resolve:theURL];
//    NSLog(@"fetch absolute: %@",theURL);
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithURL:theURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        NSLog(@"got back with result %@ for %@",response,theURL);
//        NSLog(@"data: %@",[data stringValue]);
        if (data && !error /* && [response statusCode] < 400 */ ){
            [target writeObject:data];
            [target close];
        } else {
            [self reportError:error];
            [target writeObject:nil];
        }
    }];
    [task resume];

}

-(void)writeObject:(id)anObject
{
    NSLog(@"-[%@ %@ %@]",[self class],NSStringFromSelector(_cmd),anObject);
    NSLog(@"streamWriterMessage: %@",NSStringFromSelector(streamWriterMessage));
    [super writeObject:anObject];
//    [anObject performSelector:[[self class] streamWriterMessage] withObject:self];
}


@end



@implementation NSString(writeOnURLFetchStream)

-(void)writeOnURLFetchStream:(MPWURLFetchStream*)aStream
{
//    NSLog(@"[%@ writeOnURLFetchStream:%@]",self,aStream);
    [aStream writeString:self];
}

@end

@implementation NSURL(writeOnURLFetchStream)

-(void)writeOnURLFetchStream:(MPWURLFetchStream*)aStream
{
    NSLog(@"[%@ writeOnURLFetchStream:%@]",self,aStream);
    [aStream fetch:self];
}

@end