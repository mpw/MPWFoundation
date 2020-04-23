//
//  MPWObjectBuilder.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 27.06.19.
//

#import "MPWObjectBuilder.h"
#import "MPWWriteStream.h"

#define ARRAYTOS        (NSMutableArray*)(*tos)
#define DICTTOS         (NSMutableDictionary*)(*tos)



@implementation MPWObjectBuilder

-(void)setupAcceessors:(Class)theClass
{
    NSArray *ivars=[theClass ivarNames];
    ivars=(NSArray*)[[ivars collect] substringFromIndex:1];
    NSMutableArray *accessors=[NSMutableArray arrayWithCapacity:ivars.count];
    for (NSString *ivar in ivars) {
        MPWValueAccessor *accessor=[MPWValueAccessor valueForName:ivar];
        [accessor bindToClass:theClass];
        [accessors addObject:accessor];
    }
    MPWSmallStringTable *table=[[[MPWSmallStringTable alloc] initWithKeys:ivars values:accessors] autorelease];
    self.accessorTable=table;
}


-(instancetype)initWithClass:(Class)theClass
{
    self=[super init];
    self.cache=[MPWObjectCache cacheWithCapacity:20 class:theClass];
    [self setupAcceessors:theClass];
    [self.cache setUnsafeFastAlloc:YES];
    self.streamingThreshold=0;
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
        [self.target writeObject:[ARRAYTOS lastObject]];
        [ARRAYTOS removeLastObject];
    }
}


-(void)writeString:(NSString*)aString
{
    if ( keyStr ) {
        MPWValueAccessor *accesssor=OBJECTFORSTRINGLENGTH(self.accessorTable, keyStr, keyLen);
        [accesssor setValue:aString forTarget:*tos];
        keyStr=NULL;
    } else {
        [self pushObject:aString];
    }
}


-(void)writeNumber:(NSString*)number
{
    if ( keyStr ) {
        MPWValueAccessor *accesssor=OBJECTFORSTRINGLENGTH(_accessorTable, keyStr, keyLen);
        [accesssor setValue:number forTarget:*tos];
        keyStr=NULL;
    } else {
        [self pushObject:number];
    }
}

-(void)writeInteger:(long)number
{
    if ( keyStr ) {
        MPWValueAccessor *accesssor=OBJECTFORSTRINGLENGTH(_accessorTable, keyStr, keyLen);
        [accesssor setIntValue:number forTarget:*tos];
        keyStr=NULL;
    } else {
        [self pushObject:@(number)];
    }
}


-(void)writeObject:anObject forKey:aKey
{
    MPWValueAccessor *accesssor=[self.accessorTable objectForKey:aKey];
    [accesssor setValue:anObject forTarget:*tos];
}

-(void)dealloc
{
    [_cache release];
    [(id)_target release];
    [super dealloc];
}


@end

@implementation MPWObjectBuilder(testing)

+(NSArray*)testSelectors
{
    return @[
             ];
}

@end
