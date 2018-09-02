//
//  MPWPipeline.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/05/16.
//
//

#import <MPWFoundation/MPWFilter.h>

@interface MPWPipeline : MPWFilter

@property (nonatomic, strong, readonly) NSArray *filters;

+(instancetype)filters:(NSArray *)filters;
-(instancetype)initWithFilters:(NSArray *)filters;
-(void)setErrorTarget:newErrorTarget;
-(void)addFilter:(id <Streaming>)newFilter;

@end


@interface MPWPipe : MPWPipeline {}   // compatibility, remove once clients have been updated to MPWPipeline
@end

