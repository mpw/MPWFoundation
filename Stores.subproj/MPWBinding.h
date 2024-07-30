//
//  MPWBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWIdentifier.h>
#import <MPWFoundation/MPWWriteStream.h>
#import <MPWFoundation/MPWAbstractStore.h>

@class MPWIdentifier,MPWAbstractStore;
@protocol MPWIdentifying,MPWStorage;

@protocol MPWBinding

+(instancetype)bindingWithReference:aReference inStore:aStore;
-(instancetype)initWithReference:aReference inStore:aStore;

@property (nonatomic, retain) id value;

-(void)delete;

-(id <MPWStorage>)asScheme;

// hierarchy support

-(BOOL)hasChildren;
-(NSArray*)children;
-(NSURL*)URL;


@end



@interface MPWBinding : NSObject<MPWBinding,MPWIdentifying,Streaming>

@property (nonatomic, strong) id <MPWIdentifying> reference;
@property (nonatomic, strong) MPWAbstractStore *store;

-(NSString*)path;
-(id <MPWIdentifying>)asReference;
-(BOOL)isBound;


-(id)ifBound:aBlock;
-(id)ifNotBound:aBlock;

@end
