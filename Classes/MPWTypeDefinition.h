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

+(instancetype)descritptorForObjcCode:(unsigned char)typeCode;
+(instancetype)descritptorForSTTypeName:(NSString*)typeName;
+(instancetype)voidType;
+(instancetype)idType;

@end

NS_ASSUME_NONNULL_END
