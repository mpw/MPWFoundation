//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference;

@protocol MPWStorage

-objectForReference:(MPWReference*)aReference;
-(void)setObject:theObject forReference:(MPWReference*)aReference;
-(void)deleteObjectForReference:(MPWReference*)aReference;

-(MPWReference*)referenceForName:(NSString*)name;

@end


@interface MPWAbstractStore<__covariant ReferenceType, __covariant ObjectType> : NSObject<MPWStorage>

-(ObjectType)objectForReference:(ReferenceType)aReference;
-(void)setObject:(ObjectType)theObject forReference:(ReferenceType)aReference;
-(void)deleteObjectForReference:(ReferenceType)aReference;

-(ReferenceType)referenceForName:(NSString*)name inContext:aContext;
-(ReferenceType)referenceForName:(NSString*)name;

@end

