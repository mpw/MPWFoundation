//
//  MPWExternalFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/29/17.
//
//

#import "MPWExternalFilter.h"
#import "MPWFDStreamSource.h"
#import "MPWByteStream.h"
#import "NSStringAdditions.h"

@interface MPWExternalFilter ()

@property (nonatomic, strong) NSString *commandString;
@property (nonatomic, assign) int fdout,fdin,pid;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, strong) MPWFDStreamSource *source;


@end


@implementation MPWExternalFilter

+(instancetype)filterWithCommandString:(NSString *)command
{
    return [[[self alloc] initWithCommandString:command] autorelease];
}

-(BOOL)runCommand:(NSString *)theCommand
{
    const char *s=[theCommand fileSystemRepresentation];
    BOOL success=NO;
    int pipeFDsOut[2];
    int pipeFDsIn[2];
    pipe( pipeFDsOut);
    pipe( pipeFDsIn);
    
    self.fdout=pipeFDsOut[1];
    self.fdin=pipeFDsIn[0];
    switch (self.pid=fork())
    {
        case -1:
            break;
        case 0:
//            fprintf(stderr,"child process with %s\n",s);
            dup2( pipeFDsOut[0], 0);       //  pipe to stdin (of child process)
            dup2( pipeFDsIn[1], 1);       //  pipe from stdout (of child process)
            close( pipeFDsIn[1]);
            close( pipeFDsOut[0]);
            close( pipeFDsIn[0]);
            close( pipeFDsOut[1]);
            system( s);
//            fprintf(stderr,"did execute %s\n",s);
            exit(0);
        default:
            success=YES;
            break;
    }
//    NSLog(@"pid: %d",self.pid);
    close(pipeFDsOut[0] );
    close(pipeFDsIn[1] );
    self.running=success;
    return success;
}

-(BOOL)run
{
    if ( [self runCommand:self.commandString] ) {
        [self.source setFdin:self.fdin];
        [[self source] runInThread];
        return YES;
    }
    return NO;
}

-(instancetype)initWithCommandString:(NSString *)command
{
    self=[super initWithTarget:nil];
    self.commandString=command;
    self.source = [[MPWFDStreamSource new] autorelease];
    [self setTarget:[self defaultTarget]];
    return self;
}


-(void)setTarget:(id)newVar
{
    [self.source setTarget:newVar];
}

-(id)target
{
    return [self.source target];
}

-(void)writeObject:anObject sender:aSender
{
    if ( !self.running)  {
        [self run];
    }
//    NSLog(@"will write: %@",anObject);
    @autoreleasepool {
        NSData *dataToWrite=[anObject asData];
        if ( [dataToWrite length]) {
            write( self.fdout, [dataToWrite bytes], [dataToWrite length] );
        }
    }
//    NSLog(@"did write: %@",anObject);
}



-(void)flushLocal
{
//    NSLog(@"will close");
    close(self.fdout);
    int stat_loc=0;
    waitpid( self.pid,&stat_loc, 0 );
    self.fdout=-1;
    self.running=NO;
//    NSLog(@"did waitpid()");
}

-(void)dealloc
{
    [self closeLocal];
    [self.source release];
    [super dealloc];
}

-(id)defaultTarget
{
    return [MPWByteStream streamWithTarget:[NSMutableString string]];
}

@end

#import "DebugMacros.h"

@implementation MPWExternalFilter(testimng)

+(void)testUpcaseViaUnixTR
{
    MPWExternalFilter *filter=[self filterWithCommandString:@"tr '[a-z]' '[A-Z]'"];
    [filter writeObject:@"hello world!"];
    [filter close];
    IDEXPECT( [[filter target] target], @"HELLO WORLD!",@"upcase");
    
}


+testSelectors
{
    return @[
             @"testUpcaseViaUnixTR",
             ];
    
}

@end
