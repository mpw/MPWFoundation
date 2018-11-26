//
//  NSBundleConveniences.h
//  MPWFoundation
//
//  Created by marcel on Fri Aug 31 2001.
/*  
    Copyright (c) 2001-2017 by Marcel Weiher.  All rights reserved.
*/
//

#import <Foundation/Foundation.h>


@interface NSBundle(Conveniences) 

+(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType forClass:(Class)aClass;
+loadFramework:(NSString*)frameworkName;
+(void)addFrameworkSearchPath:newPath;
+frameworkPathForFrameworkName:(NSString*)frameworkName;

@end

@interface NSObject(bundleConveniences)

-(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType;


@end

