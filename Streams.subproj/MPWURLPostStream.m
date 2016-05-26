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
//    NSLog(@"should encode dictionary: %@",aDict);
    for ( NSString *key in aDict.allKeys ) {
        [s printFormat:@"%@%@=%@",first?@"":@"&", key,aDict[key]];
        first=NO;
    }
//    NSLog(@"encoded dict: '%@'",[[s target] stringValue]);
    [self writeObject:[s target]];
}




-(void)writeData:(NSData *)d
{
    [self post:d toURL:nil];
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
