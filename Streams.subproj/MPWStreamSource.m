//
//  MPWStreamSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/12/17.
//
//

#import "MPWStreamSource.h"
#import <MPWWriteStream.h>



@implementation MPWStreamSource

@synthesize  target;

-(void)run
{
    ;
}

-(void)runInThread
{
    [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}


-(void)dealloc
{
    [target release];
    [super dealloc];
}

@end
