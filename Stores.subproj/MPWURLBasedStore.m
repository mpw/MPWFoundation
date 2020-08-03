//
//  MPWURLBasedStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/11/18.
//

#import "MPWURLBasedStore.h"
#import "MPWURLReference.h"
#import "MPWPathRelativeStore.h"

@implementation MPWURLBasedStore

+(id <MPWStorage>)storeAtURL:(NSURL *)url
{
    MPWGenericReference *baseRef=[MPWGenericReference referenceWithPath:url.path];
    MPWPathRelativeStore *rel=[MPWPathRelativeStore storeWithSource:[self store] reference:baseRef];
    return rel;
}


-(MPWReference*)referenceForPath:(NSString*)path
{
    return [MPWURLReference referenceWithPath:path];
}

@end
