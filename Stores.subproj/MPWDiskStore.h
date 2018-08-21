//
//  MPWDiskStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWURLBasedStore.h>

@interface MPWDiskStore : MPWURLBasedStore

-(NSURL*)fileURLForReference:(id <MPWReferencing>)ref;
-(NSArray*)childrenOfReference:(id <MPWReferencing>)aReference;

@end
