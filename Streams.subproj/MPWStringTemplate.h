//
//  MPWStringTemplate.h
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 04.02.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWByteStream;

@interface MPWStringTemplate : NSObject

+(instancetype)templateWithString:(NSString*)s;
-(instancetype)initWithString:(NSString*)s;
-(void)writeOnByteStream:(MPWByteStream*)aStream withBindings:bindings;


@end


@interface NSString(templateEval)

-(NSString*)evaluateAsTemplateWith:env;

@end

NS_ASSUME_NONNULL_END
