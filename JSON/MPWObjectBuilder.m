//
//  MPWObjectBuilder.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 27.06.19.
//

#import "MPWObjectBuilder.h"
#import "MPWWriteStream.h"

#define ARRAYTOS        (NSMutableArray*)(tos->container)
#define DICTTOS         (NSMutableDictionary*)(tos->container)



@implementation MPWObjectBuilder

-(MPWSmallStringTable*)accessorsForClass:(Class)theClass
{
    NSArray *ivars=[theClass ivarNames];
    if ( [[ivars lastObject] hasPrefix:@"_"]) {
        ivars=(NSArray*)[[ivars collect] substringFromIndex:1];
    }
    NSMutableArray *accessors=[NSMutableArray arrayWithCapacity:ivars.count];
    for (NSString *ivar in ivars) {
        MPWValueAccessor *accessor=[MPWValueAccessor valueForName:ivar];
        [accessor bindToClass:theClass];
        [accessors addObject:accessor];
    }
    MPWSmallStringTable *table=[[[MPWSmallStringTable alloc] initWithKeys:ivars values:accessors] autorelease];
    return table;
}

-(void)setupAccessors:(Class)theClass
{
    self.accessorTable=[self accessorsForClass:theClass];
}

-(MPWSmallStringTable*)accessorTablesForClassDict:(NSDictionary*)classesByKey

{
    NSMutableArray *accessorTables=[NSMutableArray array];
    NSArray *keys=[classesByKey allKeys];
    for ( NSArray *classKey in keys) {
        Class theClass=classesByKey[classKey];
        MPWSmallStringTable *accessorTable=[self accessorsForClass:theClass];
        [accessorTables addObject:accessorTable];
    }
    MPWSmallStringTable *tables=[[[MPWSmallStringTable alloc] initWithKeys:keys values:accessorTables] autorelease];
    return tables;
}

-(void)setClassesForKeys:(NSDictionary*)classesByKey
{
    self.classTable=classesByKey;
    self.accessorTablesByKey=[self accessorTablesForClassDict:classesByKey];
}


-(instancetype)initWithClass:(Class)theClass
{
    self=[super init];
    self.cache=[MPWObjectCache cacheWithCapacity:20 class:theClass];
    [self setupAccessors:theClass];
    [self.cache setUnsafeFastAlloc:YES];
    self.streamingThreshold=0;
    return self;
}

-(void)beginArray
{
    _arrayDepth++;
    NSString *theKey=self.key;
    [super beginArray];
    if ( theKey ) {
        tos->lookup=[self.accessorTablesByKey objectForKey:theKey];
        tos->class=[self classTable][theKey];
    }
}

-(void)endArray
{
    _arrayDepth--;
    [super endArray];
}

-(void)beginDictionary
{
    id container=nil;
    MPWSmallStringTable *table=nil;
    if (self.key ) {
        table=[self.accessorTablesByKey objectForKey:self.key];
        container = [[[self.classTable[self.key] alloc] init] autorelease];
    }
    if (!table) {
        if ( tos-containerStack > 0 && (table=tos->lookup)) {
            container=[[[tos->class alloc] init] autorelease];
        }
        if (!table) {
            table=self.accessorTable;
        }

    }
    if (!container) {
        container=GETOBJECT(_cache);        container=GETOBJECT(_cache);
    }
    [self pushContainer:container ];
    tos->lookup=table;
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
    if ( key ) {
        MPWValueAccessor *accesssor=[tos->lookup objectForKey:key];
        [accesssor setValue:aString forTarget:tos->container];
        key=NULL;
    } else {
        [self pushObject:aString];
    }
}


-(void)writeNumber:(NSString*)number
{
    if ( key ) {
        MPWValueAccessor *accesssor=[tos->lookup objectForKey:key];
        [accesssor setValue:number forTarget:tos->container];
        key=nil;
    } else {
        [self pushObject:number];
    }
}

-(void)writeInteger:(long)number
{
    if ( key ) {
        MPWValueAccessor *accesssor=[tos->lookup objectForKey:key];
        [accesssor setIntValue:number forTarget:tos->container];
        key=nil;
    } else {
        [self pushObject:@(number)];
    }
}


-(void)writeObject:anObject forKey:aKey
{
    MPWValueAccessor *accesssor=[tos->lookup objectForKey:aKey];
    [accesssor setValue:anObject forTarget:tos->container];
}

-(void)dealloc
{
    [_cache release];
    [(id)_target release];
    [super dealloc];
}


@end

@interface MPWJSONFlatDecodeTestClass : NSObject {}
@property (assign) long a,b;
@property (strong) id c;
@end
@implementation MPWJSONFlatDecodeTestClass
@end

@interface MPWJSONNestedDecodeTestClass : NSObject {}
@property (strong) MPWJSONFlatDecodeTestClass* firstNested;
@property (strong) NSArray<MPWJSONNestedDecodeTestClass*> *secondNested;
@property (assign) long nestedInt;
@property (strong) NSString* nestedString;

@end
@implementation MPWJSONNestedDecodeTestClass
@end

#import "MPWMASONParser.h"

@implementation MPWObjectBuilder(testing)

+(void)testDecodeFlatClassArray
{
    NSData *jsonArrayOfFlatObjects=[@"[ { \"a\": 2, \"b\": 3, \"c\": \"First\" } , { \"a\": 20, \"b\": 10, \"c\": \"Second\"} ]" asData];
    MPWObjectBuilder *builder=[[[self alloc] initWithClass:[MPWJSONFlatDecodeTestClass class]] autorelease];
    MPWMASONParser *parser=[[[MPWMASONParser alloc] initWithBuilder:builder] autorelease];
    NSArray *result = [parser parsedData:jsonArrayOfFlatObjects];
    INTEXPECT(result.count, 2, @"parsed array count");
    MPWJSONFlatDecodeTestClass *first=result.firstObject;
    INTEXPECT(first.a, 2, @"first.a");
    INTEXPECT(first.b, 3, @"first.b");
    IDEXPECT(first.c, @"First", @"first.c");
    MPWJSONFlatDecodeTestClass *last=result.lastObject;
    INTEXPECT(last.a, 20, @"last.a");
    INTEXPECT(last.b, 10, @"last.b");
    IDEXPECT(last.c, @"Second", @"last.c");
}

+(void)testDecodeNestedObject
{
    NSData *jsonNestedObjects=[@"[ { \"nestedInt\": 7,  \"nestedString\": \"FirstNested\"  \"firstNested\": { \"a\": 17, \"b\": 23, \"c\": \"SubObject\" } }  ]" asData];
    MPWObjectBuilder *builder=[[[self alloc] initWithClass:[MPWJSONNestedDecodeTestClass class]] autorelease];
    [builder setClassesForKeys:@{ @"firstNested": [MPWJSONFlatDecodeTestClass class] }];
    MPWMASONParser *parser=[[[MPWMASONParser alloc] initWithBuilder:builder] autorelease];
    NSArray *result = [parser parsedData:jsonNestedObjects];
    INTEXPECT(result.count, 1, @"parsed array count");
    MPWJSONNestedDecodeTestClass *first=result.firstObject;
    INTEXPECT(first.nestedInt, 7, @"first.nestedInt");
    IDEXPECT(first.nestedString, @"FirstNested", @"first.nestedString");
    MPWJSONFlatDecodeTestClass *firstSubObject=first.firstNested;
    EXPECTNOTNIL(firstSubObject, @"there should be a subobject");

    INTEXPECT(firstSubObject.a, 17, @"firstSubObject.a");
    INTEXPECT(firstSubObject.b, 23, @"firstSubObject.b");
    IDEXPECT(firstSubObject.c, @"SubObject", @"firstSubObject.c");
}

+(void)testDecodeNestedArrayWithObjects
{
    NSData *jsonNestedObjects=[@"[ { \"nestedInt\": 7,  \"nestedString\": \"FirstNested\"  \"secondNested\": [{ \"a\": 17, \"b\": 23, \"c\": \"SubObject\" } ] }  ]" asData];
    MPWObjectBuilder *builder=[[[self alloc] initWithClass:[MPWJSONNestedDecodeTestClass class]] autorelease];
    [builder setClassesForKeys:@{ @"secondNested": [MPWJSONFlatDecodeTestClass class] }];
    MPWMASONParser *parser=[[[MPWMASONParser alloc] initWithBuilder:builder] autorelease];
    NSArray *result = [parser parsedData:jsonNestedObjects];
    INTEXPECT(result.count, 1, @"parsed array count");
    MPWJSONNestedDecodeTestClass *first=result.firstObject;
    INTEXPECT(first.nestedInt, 7, @"first.nestedInt");
    IDEXPECT(first.nestedString, @"FirstNested", @"first.nestedString");
    NSArray *nestedArray=first.secondNested;
    INTEXPECT(nestedArray.count, 1, @"elements in nested array");
    MPWJSONFlatDecodeTestClass *firstSubObject=nestedArray.firstObject;


   INTEXPECT(firstSubObject.a, 17, @"firstSubObject.a");
//    INTEXPECT(firstSubObject.b, 23, @"firstSubObject.b");
//    IDEXPECT(firstSubObject.c, @"SubObject", @"firstSubObject.c");
}

+(NSArray*)testSelectors
{
    return @[
        @"testDecodeFlatClassArray",
        @"testDecodeNestedObject",
        @"testDecodeNestedArrayWithObjects",
             ];
}

@end
