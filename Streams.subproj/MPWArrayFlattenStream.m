//
//  MPWArrayFlattenStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/18.
//

#import "MPWArrayFlattenStream.h"


@implementation NSObject(MPWFlattening)

-(void)flattenOntoStream:(MPWArrayFlattenStream*)aStream
{
    [aStream writeNSObject:self];
}

@end

@implementation MPWArrayFlattenStream


-(SEL)streamWriterMessage
{
    return @selector(flattenOntoStream:);
}

-(void)writeArray:(NSArray*)anArray
{
    [[anArray objectEnumerator] writeOnStream:self];
}

@end



@implementation NSEnumerator(MPWFlattening)

-(void)flattenOntoStream:(MPWArrayFlattenStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end


@implementation NSArray(MPWFlattening)

-(void)flattenOntoStream:(MPWArrayFlattenStream*)aStream
{
    [aStream writeArray:self];
}

@end

