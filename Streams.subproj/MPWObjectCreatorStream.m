//
//  MPWObjectCreatorStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 16/05/16.
//
//

#import "MPWObjectCreatorStream.h"

@interface MPWObjectCreatorStream()

@property (assign) Class targetClass;

@end


@implementation MPWObjectCreatorStream


+streamWithClass:(Class)newTargetClass
{
    return [[[self alloc] initWithClass:newTargetClass target:nil] autorelease];
}

-initWithClass:(Class)newTargetClass target:newTarget
{
    self=[super initWithTarget:newTarget];
    self.targetClass=newTargetClass;
    
    return self;
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnObjectCreationStream:);
}


-(void)writeDictionary:(NSDictionary *)aDictionary
{
    id anObject=[[self.targetClass alloc] initWithDictionary:aDictionary];
    [target writeObject:anObject];
    [anObject release];
}

-(void)writeData:(NSData *)someData
{
    id anObject=[[self.targetClass alloc] initWithData:someData];
    [target writeObject:anObject];
    [anObject release];
}

@end


@implementation NSObject(StreamClassCreating)

-(void)writeOnObjectCreationStream:(MPWObjectCreatorStream *)aStream
{
    [self flattenOntoStream:aStream];
}

@end

@implementation NSData(StreamClassCreating)

-(void)writeOnObjectCreationStream:(MPWObjectCreatorStream *)aStream
{
    [aStream writeData:self];
}

@end
