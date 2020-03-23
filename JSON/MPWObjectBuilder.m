//
//  MPWObjectBuilder.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 27.06.19.
//

#import "MPWObjectBuilder.h"

#define ARRAYTOS        (NSMutableArray*)(*tos)
#define DICTTOS         (NSMutableDictionary*)(*tos)


@implementation MPWObjectBuilder

-(instancetype)initWithClass:(Class)theClass
{
    self=[super init];
    self.cache=[MPWObjectCache cacheWithCapacity:20 class:theClass];
    self.streamingThreshold=1;
    return self;
}

-(void)beginArray
{
    _arrayDepth++;
    [super beginArray];
}

-(void)endArray
{
    _arrayDepth--;
    [super endArray];
}

-(void)beginDictionary
{
    [self pushContainer:GETOBJECT(_cache) ];
}

-(void)endDictionary
{
    tos--;
    if ( _arrayDepth <= _streamingThreshold) {
        [self.target writeObject:[ARRAYTOS lastObject] sender:self];
        [ARRAYTOS removeLastObject];
    }
    _objectCount++;
}

-(void)writeObject:anObject forKey:aKey
{
    [*tos setValue:anObject forKey:aKey];
}



@end

@implementation MPWObjectBuilder(testing)

+(NSArray*)testSelectors
{
    return @[
             ];
}

@end
