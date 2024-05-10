//
//  MPWTemplateMatchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import <MPWFoundation/MPWFoundation.h>

//_Pragma("clang assume_null begin")

typedef struct {
     void  * _Nullable propertyPath;
    _Nullable IMP      function;
     void *   _Nullable method;
} PropertyPathDef;

typedef struct {
    MPWRESTVerb verb;
    int count;
    PropertyPathDef defs[];
} PropertyPathDefs;

extern PropertyPathDefs * _Nonnull  makePropertyPathDefs( MPWRESTVerb verb, int count, PropertyPathDef  * _Nonnull theDefs);


@interface MPWTemplateMatchingStore : MPWAbstractStore

#if GNUSTEP
@property (nonatomic, strong) id _Nullable target;
#else
@property (nonatomic, weak) id _Nullable target;
#endif

-(instancetype _Nullable )initWithPropertyPathDefs:(PropertyPathDef  *_Nullable)newDefs  count:(int)count;
-(id _Nullable )at:(id<MPWReferencing>_Nullable)aReference for:target with:(_Nullable id *_Nullable)extraParams count:(int)extraParamCount;

//_Pragma("clang assume_null end")
-(void)setContext:aContext;


@end


