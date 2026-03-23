//
//  MPWDictColumn.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 23.03.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWDictColumn : MPWTableColumn

+(instancetype)columnWithArray:(NSArray*)array key:(NSString*)aKey;
-(instancetype)intWithArray:(NSArray*)array key:(NSString*)aKey;

-(id)objectAtIndex:(NSUInteger)anIndex;

@end

NS_ASSUME_NONNULL_END
