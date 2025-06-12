//
//  MPWRusage.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 28/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "MPWRusage.h"
#import <Foundation/Foundation.h>
#import "MPWTrampoline.h"
#include <time.h>


@implementation MPWRusage

scalarAccessor(long long, absolute , setAbsolute)
scalarAccessor(long long, cpu , setCpu)

static long long getNanoseconds(int which) {
    struct timespec ts;
    clock_gettime(which,&ts );

    return ts.tv_sec * 1000000000 + ts.tv_nsec;
}
static long long getRealNanoseconds(void) {
    return getNanoseconds(CLOCK_REALTIME);
}

static long long getCPUNanoseconds(void) {
    return getNanoseconds(CLOCK_PROCESS_CPUTIME_ID);
}




-initWithCurrent
{
        if (nil != (self=[super init])) {
            getrusage( RUSAGE_SELF, &usage );
            absolute=getRealNanoseconds();
            cpu=getCPUNanoseconds();
        }
        return self;
}

+current {
        return [[[self alloc] initWithCurrent] autorelease];
}



-(struct rusage*)usage {
        return &usage;
}

-(struct timeval)timevalFrom:(struct timeval)tvstart to:(struct timeval)tvstop
{
        tvstop.tv_sec -= tvstart.tv_sec;
        tvstop.tv_usec -= tvstart.tv_usec;
        if ( tvstop.tv_usec < 0 ) {
                tvstop.tv_sec--;
                tvstop.tv_usec+=1000000;
        }
        return tvstop;
}

-(long)microsecondsForTimeVal:(struct timeval)timeval
{
        return timeval.tv_sec  * 1000000 + timeval.tv_usec;
}

-(long)systemMicroseconds {
        return [self microsecondsForTimeVal:usage.ru_stime];
}

-(long)userMicroseconds {
        return [self microsecondsForTimeVal:usage.ru_utime];
}

-(double)absoluteNS
{
    return absolute;
}

-(int)absoluteMicroseconds
{
    return [self absoluteNS] / 1000;
}



-subtractStartTime:(MPWRusage*)start
{
    struct rusage start_usage;
    //      NSAssert( start != nil );
    start_usage=*[start usage];
    usage.ru_utime = [self timevalFrom:start_usage.ru_utime to: usage.ru_utime];
    usage.ru_stime = [self timevalFrom:start_usage.ru_stime to: usage.ru_stime];
    absolute -= [start absolute];
    cpu -= [start cpu];
#define USAGE_SUBTRACT( member )  usage.member -= start_usage.member

    USAGE_SUBTRACT(  ru_maxrss);          /* integral max resident set size */
    USAGE_SUBTRACT(  ru_ixrss);           /* integral shared text memory size */
    USAGE_SUBTRACT(  ru_idrss);           /* integral unshared data size */
    USAGE_SUBTRACT(  ru_isrss);           /* integral unshared stack size */
    USAGE_SUBTRACT(  ru_minflt);          /* page reclaims */
    USAGE_SUBTRACT(  ru_majflt);          /* page faults */
    USAGE_SUBTRACT(  ru_nswap);           /* swaps */
    USAGE_SUBTRACT(  ru_inblock);         /* block input operations */
    USAGE_SUBTRACT(  ru_oublock);         /* block output operations */
    USAGE_SUBTRACT(  ru_msgsnd);          /* messages sent */
    USAGE_SUBTRACT(  ru_msgrcv);          /* messages received */
    USAGE_SUBTRACT(  ru_nsignals);        /* signals received */
    USAGE_SUBTRACT(  ru_nvcsw);           /* voluntary context switches */
    USAGE_SUBTRACT(  ru_nivcsw);          /* involuntary context switches */

    return self;
}

+timeRelativeTo:(MPWRusage*)start
{
        return [[self current] subtractStartTime:start];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: userMicros: %ld >",[self class],self,[self userMicroseconds]];
}


@end

