//
//  MPWMergingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/11/18.
//

#import "MPWMergingStore.h"
#import "MPWDictStore.h"

@implementation MPWMergingStore

#define BOTHOFCLASS( c )  ([existingObject isKindOfClass:[c class]] && [newObject isKindOfClass:[c class]])

-mergeNew:newObject into:existingObject forReference:(id <MPWIdentifying>)aReference
{
    if ( BOTHOFCLASS(NSArray)) {
        return [(NSArray*)existingObject arrayByAddingObjectsFromArray:(NSArray*)newObject];
    } else if ( BOTHOFCLASS(NSString) ) {
        return [(NSString*)existingObject stringByAppendingString:(NSString*)newObject];
    } else {
        return newObject == nil ? existingObject : newObject;
    }
}


-(void)merge:theObject at:(id <MPWIdentifying>)aReference
{
    id source=[self at:aReference];
    id merged=theObject ? theObject : source;
    if ( source && theObject) {
        merged=[self mergeNew:theObject into:source forReference:aReference];
    }
    if ( merged ) {
        [self at:aReference put:merged];
    }
}

@end

#import "DebugMacros.h"

@implementation MPWMergingStore(testing)


+(void)testNSArrayMerge
{
    MPWDictStore *source=[MPWDictStore store];
    id <MPWIdentifying> r=[source referenceForPath:@"hi"];
    MPWMergingStore *merger=[self storeWithSource:source];
    [merger merge:@[ @(1)] at:r];
    IDEXPECT( merger[r],@[ @(1)], @"merge onto empty is new");
    [merger merge:@[ @(2)] at:r];
    IDEXPECT( merger[r],(@[ @(1),@(2)]), @"merge onto non-empty is concat");
}

+testSelectors
{
    return @[
             @"testNSArrayMerge",
             ];
}


@end
