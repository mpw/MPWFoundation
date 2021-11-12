//
//  MPWDirectoryStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 12.11.21.
//

#import "MPWDirectoryStore.h"
#import "MPWFileChangesStream.h"
#import "MPWPathMapper.h"

@implementation MPWDirectoryStore

-(id <StreamSource>)log
{
    MPWFileChangesStream *changeDetector = [[[MPWFileChangesStream alloc] initWithDirectoryPath:self.baseReference.path] autorelease];
    MPWPathMapper *pathMapper = [[MPWPathMapper new] autorelease];
    [pathMapper setPrefix:self.baseReference];
    [changeDetector setTarget:pathMapper];
    [changeDetector start];
    return changeDetector;
}

@end
