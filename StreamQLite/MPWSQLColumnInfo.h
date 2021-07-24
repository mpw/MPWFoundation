//
//  MPWSQLColumnInfo.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.07.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWSQLColumnInfo : NSObject

@property (nonatomic, assign)  BOOL pk;
@property (nonatomic, assign)  BOOL notnull;
@property (nonatomic, strong)  NSString *name;
@property (nonatomic, strong)  NSString *type;
@property (readonly) NSString *objcType;

@end

NS_ASSUME_NONNULL_END
