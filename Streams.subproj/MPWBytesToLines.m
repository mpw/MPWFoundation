//
//  MPWBytesToLines.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.06.21.
//

#import "MPWBytesToLines.h"

@interface MPWBytesToLines()

@property (nonatomic, strong) NSData *remainder;

@end

@implementation MPWBytesToLines

-(void)writeData:(NSData *)data
{
    unsigned char *b=(unsigned char*)[data bytes];
    unsigned long length=[data length];
    int base=0;
    int cur=0;
    while ( cur < length) {
        if ( b[cur] == '\n') {
            NSData *line=[data subdataWithRange:NSMakeRange(base,cur-base)];
            if ( self.remainder ) {
                NSMutableData *d=[[self.remainder mutableCopy] autorelease];
                [d appendData:line];
                line=d;
                self.remainder=nil;
            }
            [self.target writeObject:[line stringValue]];
            base=cur+1;
        }
        cur++;
    }
    if ( cur > base ) {
        self.remainder = [data subdataWithRange:NSMakeRange(base,cur-base)];
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWBytesToLines(testing) 

+(void)testBasicTurnBytesIntoLines
{
    NSArray *result=[NSMutableArray array];
    NSData *orig=[@"Some\nLines\nOf\nText\n" asData];
    MPWBytesToLines *f=[self streamWithTarget:result];
    [f writeObject:orig];
    INTEXPECT([result count],4,@"number of lines");
    IDEXPECT(result[0], @"Some",@"line 1");
    IDEXPECT(result[1], @"Lines",@"line 2");
    IDEXPECT(result[2], @"Of",@"line 3");
    IDEXPECT(result[3], @"Text",@"line 4");
}

+(void)testLineRemainderGetsSaved
{
    NSArray *result=[NSMutableArray array];
    NSData *orig=[@"Some\nLines\nOf" asData];
    MPWBytesToLines *f=[self streamWithTarget:result];
    [f writeObject:orig];
    INTEXPECT([result count],2,@"number of lines");
    IDEXPECT(result[0], @"Some",@"line 1");
    IDEXPECT(result[1], @"Lines",@"line 2");
    IDEXPECT([f.remainder stringValue],@"Of",@"remainder");
}

+(void)testLineRemainderGetsUsed
{
    NSArray *result=[NSMutableArray array];
    NSData *orig1=[@"Some\nLin" asData];
    NSData *orig2=[@"es\nOf\nText\n" asData];
    MPWBytesToLines *f=[self streamWithTarget:result];
    [f writeObject:orig1];
    [f writeObject:orig2];
    INTEXPECT([result count],4,@"number of lines");
    IDEXPECT(result[0], @"Some",@"line 1");
    IDEXPECT(result[1], @"Lines",@"line 2");
    IDEXPECT(result[2], @"Of",@"line 3");
    IDEXPECT(result[3], @"Text",@"line 4");
}

+(NSArray*)testSelectors
{
   return @[
       @"testBasicTurnBytesIntoLines",
       @"testLineRemainderGetsSaved",
       @"testLineRemainderGetsUsed",
			];
}

@end
