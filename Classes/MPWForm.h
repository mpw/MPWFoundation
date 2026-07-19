//
//  MPWForm.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 13.05.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStructureDefinition;
@protocol MPWStorage;

@interface MPWForm : NSObject

@property (nonatomic, strong) MPWStructureDefinition *def;
@property (nonatomic, strong) id <MPWStorage> store;
@property (nonatomic, strong) NSString *formAction;


@end

NS_ASSUME_NONNULL_END
