//
//  MPWTemplateMatchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import <MPWFoundation/MPWFoundation.h>

//_Pragma("clang assume_null begin")

typedef struct {
     MPWReferenceTemplate  * _Nullable propertyPath;
    _Nullable IMP      function;
    _Nullable id       method;
} PropertyPathDef;

typedef struct {
    MPWRESTVerb verb;
    int count;
    PropertyPathDef defs[0];
} PropertyPathDefs;

@interface MPWTemplateMatchingStore : MPWAbstractStore

@property (nonatomic, weak) id _Nullable target;

-(instancetype _Nullable )initWithPropertyPathDefs:(PropertyPathDef  *_Nullable)newDefs _Nullablecount:(int)count;
-(id _Nullable )at:(id<MPWReferencing>_Nullable)aReference for:target with:(_Nullable id *_Nullable)extraParams count:(int)extraParamCount;

//_Pragma("clang assume_null end")
-(void)setContext:aContext;


@end


