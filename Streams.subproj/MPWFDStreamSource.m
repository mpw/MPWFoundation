//
//  MPWFDStreamSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/11/17.
//
//

#import "MPWFDStreamSource.h"
#import "MPWStream.h"

@implementation MPWFDStreamSource

-initWithFD:(int)fd
{
    self=[super init];
    self.fdin=fd;
    return self;
}

+fd:(int)fd
{
    return [[[self alloc] initWithFD:fd] autorelease];
}


-(void)readFromStreamAndWriteToTarget
{
    char buffer[8200];
    int actual=0;
    while ( (actual=read(self.fdin, buffer, 8192)) > 0 ) {
        @autoreleasepool {
            NSData *dataToWrite=[NSData dataWithBytes:buffer length:actual];
            [self.target writeObject:dataToWrite sender:self];
            
        }
    }
    self.fdin=-1;
}

-(void)run
{
    [self readFromStreamAndWriteToTarget];
}

-(void)runInThread
{
    [NSThread detachNewThreadSelector:@selector(readFromStreamAndWriteToTarget) toTarget:self withObject:nil];
}


@end
