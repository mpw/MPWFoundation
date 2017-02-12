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
    return self;
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
    char buffer[8200];
    int actual=0;
    while ( (actual=read(self.fdin, buffer, 8192)) > 0 ) {
        @autoreleasepool {
            NSData *dataToWrite=[NSData dataWithBytes:buffer length:actual];
            [self.target writeObject:dataToWrite sender:self];
            
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
