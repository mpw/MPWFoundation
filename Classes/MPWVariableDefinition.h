//
//  MPWVariableDefinition.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import <Foundation/Foundation.h>
#import <MPWFoundation/MPWRESTOperation.h>

NS_ASSUME_NONNULL_BEGIN


@class MPWTypeDefinition;

@interface MPWVariableDefinition : NSObject


-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType;
+(instancetype)idWithName:(NSString*)newName;
+(instancetype)int64WithName:(NSString*)newName;

-(NSString*)objcType;
-(unsigned char)objcTypeCode;


@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) MPWTypeDefinition *type;
@property (nonatomic,assign) MPWRESTVerb operations;
@property (nonatomic,assign) NSString *title;
/// Presentation-neutral hints such as grouping, allowed values, placeholder,
/// units or multiline intent.  Renderers may use the hints they understand.
@property (nonatomic,copy,nullable) NSDictionary *presentationMetadata;

@end

NS_ASSUME_NONNULL_END
