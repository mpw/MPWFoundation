//
//  MPWObjectBuilder.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 27.06.19.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWObjectBuilder :MPWPListBuilder

-(instancetype)initWithClass:(Class)theClass;

@property (nonatomic, strong) MPWObjectCache *cache;
@property (nonatomic, assign) long objectCount;
@property (nonatomic, assign) long arrayDepth;
@property (nonatomic, assign) long objectDepth;
@property (nonatomic, assign) long streamingThreshold;
@property (nonatomic, strong) id <Streaming> target;

@end
