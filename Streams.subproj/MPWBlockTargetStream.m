//
//  MPWBlockTargetStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 4/2/15.
//
//

#import "MPWBlockTargetStream.h"

@interface MPWBlockTargetStream()

@property (nonatomic,strong) TargetBlock block;

@end

@implementation MPWBlockTargetStream


CONVENIENCEANDINIT( stream, WithBlock:(TargetBlock)newBlock)
{
    self=[super init];
    [self setBlock:newBlock];
    streamWriterMessage=[self streamWriterMessage];
    return self;
}


-(void)writeObject:(id)anObject sender:aSender
{
    TargetBlock targetBlock = [self block];
    if ( targetBlock) {
        targetBlock(anObject);
    }
}

-(void)dealloc
{
    [_block release];
    [super dealloc];
}

@end
