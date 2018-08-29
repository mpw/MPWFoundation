//
//  MPWURLCall.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02/06/16.
//
//

#import <Foundation/Foundation.h>

@class MPWRESTOperation;
@protocol MPWReferencing;

@interface MPWURLCall : NSObject

-(instancetype)initWithURL:(NSURL *)requestURL method:(NSString *)method data:(NSData *)bodyData;
-(id)processed;

@property (nonatomic, readonly)  MPWRESTOperation  *operation;
@property (nonatomic, strong)  NSObject <MPWReferencing> *reference;

@property (nonatomic, readonly)  NSURLRequest     *request;
@property (nonatomic, strong)  NSData           *bodyData;
@property (nonatomic, strong)  NSDictionary     *headerDict;

@property (nonatomic, strong)  NSURLResponse    *response;
@property (nonatomic, strong)  NSError          *error;
@property (nonatomic, strong)  NSData           *data;
@property (nonatomic, strong)  id               processedObject;
@property (nonatomic, strong)  NSURLSessionTask *task;
@property (nonatomic, assign)  BOOL             isStreaming;

@property (readonly) NSURL* finalURL;


@end
