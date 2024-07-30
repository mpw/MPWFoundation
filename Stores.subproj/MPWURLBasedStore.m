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
    MPWGenericIdentifier *baseRef=[MPWGenericIdentifier referenceWithPath:url.path];
    MPWPathRelativeStore *rel=[MPWPathRelativeStore storeWithSource:[self store] reference:baseRef];
    return rel;
}


-(MPWIdentifier*)referenceForPath:(NSString*)path
{
    return [MPWURLReference referenceWithPath:path];
}

@end
