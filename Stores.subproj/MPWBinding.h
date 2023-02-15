//
//  MPWBinding.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWFoundation/MPWReference.h>
#import <MPWFoundation/MPWWriteStream.h>
#import <MPWFoundation/MPWAbstractStore.h>

@class MPWReference,MPWAbstractStore;
@protocol MPWReferencing,MPWStorage;

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



@interface MPWBinding : NSObject<MPWBinding,MPWReferencing,Streaming>

@property (nonatomic, strong) id <MPWReferencing> reference;
@property (nonatomic, strong) MPWAbstractStore *store;

-(NSString*)path;
-(id <MPWReferencing>)asReference;
-(BOOL)isBound;

@end
