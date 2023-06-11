//
//  MPWPropertyPath.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>


@protocol MPWReferencing;

typedef struct {
    BOOL isWildcard;
    NSString *segmentName;
    NSString *parameterName;
} ReferenceTemplateComponent;

typedef struct {
    long count;
    ReferenceTemplateComponent components[0];
} ReferenceTemplateComponents;

ReferenceTemplateComponents* componentsFromReference( id <MPWReferencing> ref );

@interface MPWReferenceTemplate : NSObject

@property (readonly) NSString *name;
@property (readonly) NSArray *formalParameters;

+(instancetype)templateWithReference:(id <MPWReferencing>)ref;
-(instancetype)initWithReference:(id <MPWReferencing>)ref;

-(NSDictionary*)bindingsForMatchedReference:(id <MPWReferencing>)ref;
-(BOOL)getParameters:(NSString **)params  forMatchedReference:(id <MPWReferencing>)ref;
-(NSArray*)parametersForMatchedReference:(id <MPWReferencing>)ref;

@end
