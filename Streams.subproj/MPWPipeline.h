//
//  MPWPipeline.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/05/16.
//
//

#import <MPWFoundation/MPWStream.h>

@interface MPWPipeline : MPWStream

@property (nonatomic, strong, readonly) NSArray *filters;

+(instancetype)filters:(NSArray *)filters;
-(instancetype)initWithFilters:(NSArray *)filters;
-(void)setErrorTarget:newErrorTarget;
-(void)addFilter:(id <Streaming>)newFilter;

@end
