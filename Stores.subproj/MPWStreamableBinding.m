//
//  MPWStreamableBinding.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.07.22.
//

#import "MPWStreamableBinding.h"
#import "MPWFDStreamSource.h"
#import "MPWByteStream.h"
#import "MPWSkipFilter.h"
#import "MPWBytesToLines.h"

@implementation MPWStreamableBinding


-(MPWFDStreamSource*)source
{
    return nil;
}

-stream
{
    return [self source];
}

-(MPWByteStream*)writeStream
{
    return [MPWByteStream fileName:[self path]];
}


-(MPWStreamSource*)lines
{
    MPWFDStreamSource *s=[self stream];
    [s setTarget:[MPWBytesToLines stream]];
    return s;
}

-(MPWStreamSource*)linesAfter:(int)numToSkip
{
    MPWStreamSource *stream=[self lines];
    MPWSkipFilter *skipper=[MPWSkipFilter stream];
    skipper.skip = numToSkip;
    [stream setFinalTarget:skipper];
    return stream;
}



@end
