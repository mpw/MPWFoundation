//
//  MPWScatterStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWScatterStream : MPWStream

+(instancetype)filters:(NSArray *)filters;
-(instancetype)initWithFilters:(NSArray *)filters;

@end
