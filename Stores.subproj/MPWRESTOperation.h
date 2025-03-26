//
//  MPWRESTOperation.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import <Foundation/Foundation.h>


@protocol MPWIdentifying;

@interface MPWRESTOperation<T: id <MPWIdentifying>> : NSObject

typedef NS_ENUM(int, MPWRESTVerb) {
    MPWRESTVerbGET,
    MPWRESTVerbPUT,
    MPWRESTVerbPATCH,
    MPWRESTVerbDELETE,
    MPWRESTVerbPOST,
    MPWRESTVerbMAX,
    MPWRESTVerbInvalid = -1
};

@property (nonatomic,assign) MPWRESTVerb verb;
@property (nonatomic,strong) T identifier;
@property (readonly) NSString *HTTPVerb;

+(instancetype)operationWithReference:(T)reference verb:(MPWRESTVerb)verb;
-(instancetype)initWithReference:(T)reference verb:(MPWRESTVerb)verb;


@end
