//
//  MPWAbstractUIGenerator.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.06.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWTypeToObjectMapper;
@protocol MPWStorage;

@interface MPWAbstractUIGenerator : MPWFlattenStream

@property (nonatomic,strong) MPWTypeToObjectMapper *type2view;
@property (nonatomic,strong) id <MPWStorage> store;
@property (nonatomic,assign) bool debug;

-(id)controlForType:(MPWTypeDefinition*)type;
-(void)beginView:aView;
-(void)writeResetButtonForForm:(MPWForm*)aForm;


@end

NS_ASSUME_NONNULL_END
