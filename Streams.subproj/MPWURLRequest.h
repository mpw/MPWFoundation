//
//  MPWURLRequest.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02/06/16.
//
//

#import <Foundation/Foundation.h>

@interface MPWURLRequest : NSObject

-(instancetype)initWithURL:(NSURL *)requestURL method:(NSString *)method data:(NSData *)bodyData;

-(void)setHeaderDict:(NSDictionary *)headerDict;
-(void)setBodyData:(NSData *)bodyData;

-(id)processed;


@property (nonatomic, strong)  NSURLRequest  *request;
@property (nonatomic, strong)  NSURLResponse *response;
@property (nonatomic, strong)  NSError       *error;
@property (nonatomic, strong)  NSData        *data;
@property (nonatomic, assign)  BOOL          isStreaming;


@end
