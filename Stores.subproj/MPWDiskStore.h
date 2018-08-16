//
//  MPWDiskStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWURLBasedStore.h>

@interface MPWDiskStore : MPWURLBasedStore

-(NSURL*)fileURLForReference:(MPWGenericReference*)ref;
-(BOOL)isLeafReference:(MPWGenericReference *)aReference;
-(NSArray*)childrenOfReference:(MPWGenericReference*)aReference;

@end
