//
//  MPWExternalFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/29/17.
//
//

#if !TARGET_OS_IPHONE

#import "MPWExternalFilter.h"
#import "MPWFDStreamSource.h"
#import <MPWByteStream.h>
#import "NSStringAdditions.h"
#include <unistd.h>
#include <sys/wait.h>

@interface MPWExternalFilter ()

@property (nonatomic, strong) NSString *commandString;
@property (nonatomic, strong) NSArray *commandArgs;
@property (nonatomic, assign) int fdout,fdin,pid;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, strong) MPWFDStreamSource *source;


@end


@implementation MPWExternalFilter

+(instancetype)filterWithCommandString:(NSString *)command
{
    return [[[self alloc] initWithCommandString:command] autorelease];
}

+(instancetype)filterWithCommand:(NSString *)command args:(NSArray*)newArgs
{
    MPWExternalFilter *f = [[[self alloc] initWithCommandString:command] autorelease];
    f.commandArgs = newArgs;
    return f;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.commandArgs=@[];
    return self;
}

-(NSArray*)allArgs
{
    return [self commandArgs];
}

-(BOOL)runCommand:(NSString *)theCommand
{
    extern char *environ[];
    const char *s=[theCommand fileSystemRepresentation];
    NSArray *myArrags=[self allArgs];
    long numCommands=[myArrags count];
    const char *commandStrings[numCommands+2];
    commandStrings[numCommands+1]=NULL;
    commandStrings[0]=s;
    for (int i=0;i<numCommands;i++) {
        commandStrings[i+1]=[myArrags[i] UTF8String];
    }
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
            int retval = execve( s, (char**)commandStrings, environ );
            fprintf(stderr,"failed to execve %s retval: %d\n",s,retval);
            exit(retval);
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

-(void)run
{
    if ( [self runCommand:self.commandString] ) {
        [self.source setFdin:self.fdin];
        [[self source] runInThread];
    }
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

-(void)writeString:(NSString*)aString
{
    [self writeData:[aString asData]];
}

-(void)writeNSObject:(id)anObject
{
    [self writeData:[anObject asData]];
}

-(void)writeData:(NSData*)dataToWrite
{
    if ( !self.running)  {
        [self run];
    }
//    NSLog(@"will write: %@",anObject);
    @autoreleasepool {
        if ( [dataToWrite length]) {
            write( self.fdout, [dataToWrite bytes], [dataToWrite length] );
        }
    }
//    NSLog(@"did write: %@",anObject);
}


-(void)flushLocal
{
//    NSLog(@"MPWExternalFilter flushLocal");
    close(self.fdout);
    int stat_loc=0;
    waitpid( self.pid,&stat_loc, 0 );
    self.fdout=-1;
    self.running=NO;
//    NSLog(@"MPWExternalFilter did flushLocal (waitpid returned)");
}

-(void)dealloc
{
    [self closeLocal];
    [_source release];
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
//    MPWExternalFilter *filter=[self filterWithCommandString:@"tr '[a-z]' '[A-Z]'"];
    MPWExternalFilter *filter=[self filterWithCommand:@"/usr/bin/tr" args:@[@"'[a-z]'",@"'[A-Z]'"]];
    [filter writeString:@"hello world!"];
    [filter close];
    IDEXPECT( [(MPWFilter*)[filter target] target], @"HELLO WORLD!",@"upcase"); // FIXME
}


+testSelectors
{
    return @[
//             @"testUpcaseViaUnixTR",
             ];
    
}

@end

#endif  
