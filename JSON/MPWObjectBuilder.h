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
@property (nonatomic, strong) MPWSmallStringTable *accessorTable;
@property (nonatomic, strong) MPWSmallStringTable *accessorTablesByKey;
@property (nonatomic, strong) MPWSmallStringTable *cachesByKey;
@property (nonatomic, strong) NSDictionary *classTable;
@property (nonatomic, assign) long objectCount;
@property (nonatomic, assign) long objectDepth;

@end
