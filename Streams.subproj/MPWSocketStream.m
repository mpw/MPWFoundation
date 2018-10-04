//
//  MPWSocketStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 2/13/17.
//
//

#import "MPWSocketStream.h"

@interface MPWSocketStream()

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *url;


@end

@implementation MPWSocketStream

-(instancetype)initWithURL:(NSURL*)socketURL
{
    self=[super initWithTarget:nil];
    self.url=socketURL;
//    NSLog(@"url: %@",self.url);
//    NSLog(@"port: %d",[socketURL.port intValue]);
    return self;
}

-(int)port
{
    return [self.url.port intValue];
}


-(void)open
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    int port=[self port];
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)[self.url host], port, &readStream, &writeStream);
 
    self.inputStream = (NSInputStream*)readStream;
    self.outputStream = (NSOutputStream*)writeStream;
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    [self.inputStream setDelegate:self];
    CFRelease(readStream);
    CFRelease(writeStream);
}

-(void)appendBytes:(const void*)data length:(NSUInteger)count
{
    [self.outputStream write:data maxLength:count];
}



-(BOOL)forwardAvailableBytes
{
    @autoreleasepool {
        long len=0;
        uint8_t buffer[8192];
        len=[self.inputStream read:buffer maxLength:8192];
        if ( len > 0) {
            NSData *bytesRead=[NSData dataWithBytes:buffer length:len];
            FORWARD(bytesRead);
            return YES;
        }
    }
    return NO;
}

-(void)run
{
    while ( [self forwardAvailableBytes]) {
        ;
    }
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if ( aStream == self.inputStream && eventCode == NSStreamEventHasBytesAvailable){
        [self forwardAvailableBytes];
    }
}

-(void)closeInput
{
    [self.inputStream close];
}

-(void)closeOutput
{
    [self.outputStream close];
}

-(void)dealloc
{
    [_url release];
    [_inputStream release];
    [_outputStream release];
    [super dealloc];
}

@end


@implementation MPWSocketStream(testing)



+testSelectors {  return @[]; }

@end
