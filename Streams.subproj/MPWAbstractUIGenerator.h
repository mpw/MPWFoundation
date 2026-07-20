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
/// The storage combinator a generated form is bound against.  Set from
/// MPWForm.store while writing a form; field controls are bound to references
/// into this store.  Presentation-system independent (AppKit/UIKit/HTML).
@property (nonatomic,strong) id <MPWStorage> store;

-(id)controlForType:(MPWTypeDefinition*)type;
-(void)beginView:aView;
-(void)writeResetButtonForForm:(MPWForm*)aForm;


@end

NS_ASSUME_NONNULL_END
