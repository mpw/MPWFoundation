//
//  MPWTypeDefinition.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTypeDefinition : NSObject

@property (nonatomic, assign, readonly) unsigned char objcTypeCode;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong, readonly) NSString *cName;

+(instancetype)descriptorForObjcCode:(unsigned char)typeCode;
+(instancetype)descriptorForSTTypeName:(NSString*)typeName;
+(instancetype)voidType;
+(instancetype)idType;
+(instancetype)int64Type;

@end

NS_ASSUME_NONNULL_END
