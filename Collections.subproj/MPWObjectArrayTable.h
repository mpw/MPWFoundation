//
//  MPWObjectArrayTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 20.03.26.
//

#import <MPWFoundation/MPWTable.h>
#import <MPWFoundation/MPWTableColumn.h>

@class MPWPropertyBinding;

NS_ASSUME_NONNULL_BEGIN

@interface MPWObjectArrayTable : MPWTable

@property (readonly)   NSMutableArray *objects;
@property (readonly)   Class          itemClass;

+(instancetype)tableWithObjects:(NSArray*)newObjects;
-(instancetype)initWithObjects:(NSArray*)newObjects;


-(id)firstObject;
-(NSUInteger)count;
-(id)objectAtIndexedSubscript:(NSUInteger)anIndex;
-(void)setObject:anObject atIndexedSubscript:(NSUInteger)anIndex;
-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:newObject;
-(void)insertObject:newObject  atIndex:(NSUInteger)anIndex;
-(void)removeObjectAtIndex:(NSUInteger)anIndex;
-(void)addObject:newObject;

@end


@interface MPWObjectColumn : MPWTableColumn

+(instancetype)columnWithArray:(NSArray*)array key:(NSString*)aKey class:(Class)itemClass;
-(instancetype)initWithArray:(NSArray*)array key:(NSString*)aKey class:(Class)itemClass;

-(id)objectAtIndex:(NSUInteger)anIndex;

@property (nonatomic, weak) NSArray *objects;
@property (nonatomic, weak) NSString *key;
@property (nonatomic, strong)   MPWPropertyBinding *binding;


@end

NS_ASSUME_NONNULL_END
