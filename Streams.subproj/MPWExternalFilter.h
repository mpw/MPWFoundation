//
//  MPWExternalFilter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/29/17.
//
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWExternalFilter : MPWFilter
+(instancetype)filterWithCommandString:(NSString *)command;
+(instancetype)filterWithCommand:(NSString *)command args:(NSArray*)newArgs;

-(void)run;
-(NSArray*)allArgs;

@end
