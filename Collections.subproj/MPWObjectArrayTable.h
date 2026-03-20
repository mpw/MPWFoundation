//
//  MPWObjectArrayTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import <MPWFoundation/MPWTable.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWObjectArrayTable : MPWTable

-(id)firstObject;
-(NSUInteger)count;
-(id)objectAtIndexedSubscript:(NSUInteger)anIndex;

@end

NS_ASSUME_NONNULL_END
