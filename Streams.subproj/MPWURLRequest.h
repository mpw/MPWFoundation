//
//  MPWURLRequest.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 02/06/16.
//
//

#import <Foundation/Foundation.h>

@interface MPWURLRequest : NSObject

@property (nonatomic, strong)  NSURLRequest  *request;
@property (nonatomic, strong)  NSURLResponse *response;
@property (nonatomic, strong)  NSError       *error;
@property (nonatomic, strong)  NSData        *data;

@end
