//
//  MPWSQLColumnInfo.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <MPWFoundation/MPWVariableDefinition.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWSQLColumnInfo : MPWVariableDefinition

@property (nonatomic, assign)  BOOL pk;
@property (nonatomic, assign)  BOOL notnull;
@property (readonly) NSString *objcType;

@end

NS_ASSUME_NONNULL_END
