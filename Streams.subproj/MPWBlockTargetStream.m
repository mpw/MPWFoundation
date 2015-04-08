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
    return self;
}

-(void)writeObject:(id)anObject
{
    TargetBlock targetBlock = [self block];
    if ( targetBlock) {
        targetBlock(anObject);
    }
}

-(void)dealloc
{
    [self.block release];
    [super dealloc];
}

@end
