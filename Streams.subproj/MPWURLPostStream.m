//
//  MPWURLPostStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 13/05/16.
//
//

#import "MPWURLPostStream.h"
#import "MPWByteStream.h"

@implementation MPWURLPostStream

-(SEL)streamWriterMessage
{
    return @selector(writeOnURLPostStream:);
}

-(void)writeString:(NSString*)aString
{
    [self writeObject:[aString dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)writeDictionary:(NSDictionary*)aDict
{
    MPWByteStream *s=[MPWByteStream stream];
    BOOL first=YES;
    NSLog(@"should encode dictionary: %@",aDict);
    for ( NSString *key in aDict.allKeys ) {
        [s printFormat:@"%@%@=%@",first?@"":@"&", key,aDict[key]];
        first=NO;
    }
    NSLog(@"encoded dict: '%@'",[[s target] stringValue]);
    [self writeObject:[s target]];
}


-(void)post:(NSData*)theData
{
    //    NSLog(@"fetch: %@",theURL);
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[self baseURL]];
    request.HTTPBody = theData;
    request.HTTPMethod = @"POST";
    
    //    NSLog(@"fetch absolute: %@",theURL);
    NSURLSessionDataTask *task = [[self downloader] dataTaskWithRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        //        NSLog(@"got back with result %@ for %@",response,theURL);
        //        NSLog(@"data: %@",[data stringValue]);
        if ( [response statusCode] >= 400){
            error = [NSError errorWithDomain:@"network" code:[response statusCode] userInfo:@{ @"url": [self baseURL],
                                                                                               @"postData": [theData stringValue],
                                                                                               @"headers": [(NSHTTPURLResponse*)response allHeaderFields],
                                                                                               @"content": [responseData stringValue]}];
        }
        if (responseData && !error   ){
            [target writeObject:responseData];
            //            [target close];
        } else {
            [self reportError:error];
        }
    }];
    [task resume];
    
}

-(void)writeData:(NSData *)d
{
    [self post:d];
}


@end

@implementation NSObject(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [self writeOnStream:aStream];
}

@end



@implementation NSDictionary(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [aStream writeDictionary:self];
}

@end



@implementation NSData(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [aStream writeData:self];
}

@end



@implementation NSString(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [aStream writeString:self];
}

@end
