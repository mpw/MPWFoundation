//
//  MPWRESTOperation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import <Foundation/Foundation.h>


@protocol MPWReferencing;

@interface MPWRESTOperation : NSObject

typedef NS_ENUM(int, MPWRESTVerb) {
    MPWRESTVerbGET,
    MPWRESTVerbPUT,
    MPWRESTVerbPATCH,
    MPWRESTVerbDELETE,
    MPWRESTVerbPOST
};

@property (nonatomic,assign) MPWRESTVerb verb;
@property (nonatomic,strong) id <MPWReferencing> reference;
@property (readonly) NSString *HTTPVerb;

+(instancetype)operationWithReference:(id <MPWReferencing>)reference verb:(MPWRESTVerb)verb;
-(instancetype)initWithReference:(id <MPWReferencing>)reference verb:(MPWRESTVerb)verb;


@end
