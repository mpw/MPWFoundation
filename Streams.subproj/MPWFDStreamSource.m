//
//  MPWFDStreamSource.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/11/17.
//
//

#import "MPWFDStreamSource.h"
#import <MPWWriteStream.h>
#include <unistd.h>
#include <fcntl.h>


@implementation MPWFDStreamSource

-(instancetype)initWithFilename:(NSString*)name
{
    int fd=open( [name fileSystemRepresentation], O_RDONLY);
    self=[self initWithFD:fd];
    self.closeWhenDone=YES;
    return self;
}

-(instancetype)initWithFD:(int)fd
{
    self=[super init];
    self.fdin=fd;
    self.bufferSize=[self defaultBufferSize];
//    NSLog(@"bufferSize: %d default: %d",self.bufferSize,[self defaultBufferSize]);
    return self;
}

-(instancetype)init
{
    return [self initWithFD:0];
}

+(instancetype)Stdin
{
    return [[[self alloc] init] autorelease];
}

-(int)defaultBufferSize
{
    return 512 * 1024;
}

+(instancetype)fd:(int)fd
{
    return [[[self alloc] initWithFD:fd] autorelease];
}

+(instancetype)name:(NSString *)filename
{
    return [[[self alloc] initWithFilename:filename] autorelease];
}

-(void)readFromStreamAndWriteToTarget
{
    char buffer[self.bufferSize+10];
    long actual=0;
//    NSLog(@"buffersize: %d",self.bufferSize);
    while ( (actual=read(self.fdin, buffer, self.bufferSize)) > 0 ) {
        @autoreleasepool {
            NSData *dataToWrite=[NSData dataWithBytes:buffer length:actual];
            [(id)(self.target) writeObject:dataToWrite sender:self];
            
        }
    }
    if (self.closeWhenDone) {
        [self close];
    }
}

-(void)close
{
    if ( self.fdin >= 0) {
        close(self.fdin);
        self.fdin=-1;
    }
}

-(void)run
{
    [self readFromStreamAndWriteToTarget];
}

-(void)dealloc
{
    if ( self.closeWhenDone) {
        [self close];
    }
    [super dealloc];
}

@end
