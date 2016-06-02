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

-(void)writeData:(NSData *)d
{
    [self post:d toURL:nil];
}


@end

@implementation NSObject(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [self writeOnURLFetchStream:aStream];
}

@end




@implementation NSString(streamPosting)

-(void)writeOnURLPostStream:aStream
{
    [aStream writeString:self];
}

@end
