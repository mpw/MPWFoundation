//
//  MPWPropertyPath.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>


@protocol MPWIdentifying;

typedef struct {
    BOOL isWildcard;
    NSString *segmentName;
    NSString *parameterName;
} ReferenceTemplateComponent;

typedef struct {
    long count;
    ReferenceTemplateComponent components[0];
} ReferenceTemplateComponents;

ReferenceTemplateComponents* componentsFromReference( id <MPWIdentifying> ref );

@interface MPWReferenceTemplate : NSObject

@property (readonly) NSString *name;
@property (readonly) NSArray *formalParameters;

+(instancetype)templateWithReference:(id <MPWIdentifying>)ref;
-(instancetype)initWithReference:(id <MPWIdentifying>)ref;

-(NSDictionary*)bindingsForMatchedReference:(id <MPWIdentifying>)ref;
-(BOOL)getParameters:(NSString **)params  forMatchedReference:(id <MPWIdentifying>)ref;
-(NSArray*)parametersForMatchedReference:(id <MPWIdentifying>)ref;
-(int)parameterCount;

@end
