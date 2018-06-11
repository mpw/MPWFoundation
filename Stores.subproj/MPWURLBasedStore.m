//
//  MPWURLBasedStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/11/18.
//

#import "MPWURLBasedStore.h"
#import "MPWURLReference.h"

@implementation MPWURLBasedStore


-(MPWReference*)referenceForPath:(NSString*)path
{
    return [MPWURLReference referenceWithPath:path];
}

@end
