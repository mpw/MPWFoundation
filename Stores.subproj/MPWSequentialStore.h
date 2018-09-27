//
//  MPWSequentialStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/18.
//

#import <MPWFoundation/MPWAbstractStore.h>

@interface MPWSequentialStore : MPWAbstractStore

@property(nonatomic, strong) NSArray<MPWAbstractStore*> *stores;

-(BOOL)isValidResult:result forReference:aReference;     // override for specific validity requirements


@end
