//
//  MPWTemplateMatchingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.23.
//

#import <MPWFoundation/MPWFoundation.h>

//_Pragma("clang assume_null begin")

typedef struct {
    NSString *propertyPath;
    IMP      function;
    id       method;
} PropertyPathDef;

typedef struct {
    MPWRESTVerb verb;
    int count;
    PropertyPathDef defs[0];
} PropertyPathDefs;

@interface MPWTemplateMatchingStore : MPWAbstractStore

@property (nonatomic, weak) id _Nullable target;

-(id)at:(id<MPWReferencing>)aReference for:target with:(id *)extraParams count:(int)extraParamCount;

//_Pragma("clang assume_null end")
-(void)setContext:aContext;


@end


