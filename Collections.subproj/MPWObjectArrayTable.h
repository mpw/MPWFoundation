//
//  MPWObjectArrayTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import <MPWFoundation/MPWTable.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWObjectArrayTable : MPWTable

@property (readonly)   NSMutableArray *objects;
@property (readonly)   Class          itemClass;

+(instancetype)tableWithObjects:(NSArray*)newObjects;
-(instancetype)initWithObjects:(NSArray*)newObjects;


-(id)firstObject;
-(NSUInteger)count;
-(id)objectAtIndexedSubscript:(NSUInteger)anIndex;

@end

NS_ASSUME_NONNULL_END
