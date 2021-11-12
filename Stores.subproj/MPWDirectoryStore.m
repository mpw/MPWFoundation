//
//  MPWDirectoryStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 12.11.21.
//

#import "MPWDirectoryStore.h"
#import "MPWFileChangesStream.h"
#import "MPWPathMapper.h"
#import "AccessorMacros.h"


@implementation MPWDirectoryStore{
    id loggingSource;
}

lazyAccessor( MPWFileChangesStream, loggingSource, setLoggingSource, createLoggingSource )

-(id <StreamSource>)createLoggingSource
{
    MPWFileChangesStream *changeDetector = [[[MPWFileChangesStream alloc] initWithDirectoryPath:self.baseReference.path] autorelease];
    MPWPathMapper *pathMapper = [[MPWPathMapper new] autorelease];
    [pathMapper setPrefix:self.baseReference];
    [changeDetector setTarget:pathMapper];
    [changeDetector start];
    return changeDetector;
}

-(void)setLog:newLog
{
    [[self loggingSource] setFinalTarget:newLog];
}

-(MPWLoggingStore *)logger
{
    return self;
}

@end
