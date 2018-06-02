//
//  MPWResolvedReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference,MPWAbstractStore;

@protocol MPWBinding

+(instancetype)bindingWithReference:aReference inStore:aStore;

-value;
-(void)setValue:newValue;
-(void)delete;

// hierarchy support

-(BOOL)hasChildren;
-(NSURL*)URL;


@end



@interface MPWBinding : NSObject<MPWBinding>

@property (nonatomic, strong) MPWReference *reference;
@property (nonatomic, strong) MPWAbstractStore *store;


@end
