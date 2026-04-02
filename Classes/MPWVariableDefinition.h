//
//  MPWVariableDefinition.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02.04.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class MPWTypeDefinition;

@interface MPWVariableDefinition : NSObject


-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType;

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) MPWTypeDefinition *type;


@end

NS_ASSUME_NONNULL_END
