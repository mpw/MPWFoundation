//
//  NSRunLoopAdditions.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 07.05.21.
//

#import "NSRunLoopAdditions.h"

@implementation NSRunLoop(Additions)

static int interrupted=NO;

static void interrupt(int signal) {
    interrupted=YES;
}

-(void)runInterruptibly
{
    interrupted=NO;
    void (*oldsig)(void ) = signal(SIGINT,interrupt);
    while (!interrupted) {
        @autoreleasepool {
            [self runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
    putchar('\n');
    signal(SIGINT, oldsig);
}

@end
