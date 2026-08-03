//
//  MPWRESTCopyStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/5/18.
//

#import <MPWFoundation/MPWWriteStream.h>

@class MPWAbstractStore, MPWStructureDefinition;
@protocol MPWStorage;

@interface MPWRESTCopyStream : MPWWriteStream

@property (nonatomic, strong) id <MPWStorage> source,target;

-initWithSource:(id <MPWStorage>)newSource target:(id <MPWStorage>)newTarget;

-(void)copyReferences:(NSArray*)references;
-(void)copyStructureDefinition:(MPWStructureDefinition*)structure;

@end
