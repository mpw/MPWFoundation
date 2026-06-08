//
//  MPWObjectTemplate.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWObjectTemplate : NSObject

+(instancetype)templateWithClass:(Class)aClass values:(NSDictionary*)params;
-(instancetype)initWithClass:(Class)aClass values:(NSDictionary*)params;
-object;

@end

@interface NSObject(templateCreation)

-(MPWObjectTemplate*)templateWithValues:(NSDictionary*)values;

@end


NS_ASSUME_NONNULL_END
