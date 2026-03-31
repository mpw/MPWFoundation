//
//  MPWMStats.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.03.26.
//

#import "MPWMStats.h"
#import <malloc/malloc.h>


@implementation MPWMStats
{
    struct mstats stats;
}

-(instancetype)init
{
    self=[super init];
    if ( self ) {
        stats = mstats();
    }
    return self;
}


-(long)bytesUsed
{
    return stats.bytes_used;
}

+(long)bytesUsed
{
    struct mstats stats=mstats();
    return stats.bytes_used;
}

static long peak=0;

+(long)peak
{
    long current=[self bytesUsed];
    peak=MAX(peak,current);
    return peak;
}

+(void)resetPeak
{
    peak=0;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMStats(testing) 

+(void)someTest
{
    //
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
