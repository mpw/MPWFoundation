//
//  MPWJSONConverterStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.05.21.
//

#import "MPWJSONConverterStore.h"
#import "MPWResource.h"

@interface MPWJSONConverterStore()

@property (nonatomic, strong) MPWJSONWriter *writer;
@property (nonatomic, strong) MPWMASONParser *reader;
@property (nonatomic, assign) Class theConverterClass;

@end


@implementation MPWJSONConverterStore

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource
{
    self=[super initWithSource:newSource];
    self.writer = [MPWJSONWriter stream];
    self.reader = [MPWMASONParser parser];
    return self;
}

-(MPWResource*)serialized:json
{
    NSData *d=[self.writer process:json];
    MPWResource *r=[[MPWResource new] autorelease];
    [r setRawData:d];
    [r setMIMEType:@"application/json"];
    return r;
}

-(id <Streaming>)writeStreamAt:(id <MPWReferencing>)aReference
{
    [self.writer setByteTarget:[self.source writeStreamAt:aReference]];
    return self.writer;
}

-(void)at:(id <MPWReferencing>)aReference readToStream:(id <Streaming>)aStream
{
    [(MPWFilter*)aStream setFinalTarget:self.reader];
    [[self source] at:aReference readToStream:aStream];
    return ;
}


-(void)setConverterClass:(Class)aClass
{
    self.theConverterClass = aClass;
    self.reader = [[[MPWMASONParser alloc] initWithClass:aClass] autorelease];
    [self.writer createEncoderMethodForClass:aClass];
}

-(Class)converterClass
{
    return self.theConverterClass;
}

-parsedJSON:(NSData*)anObject
{
    return [self.reader process:anObject];
}

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.up ? [self serialized:anObject] :[self parsedJSON:anObject];
}

-(id)mapObjectToStore:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.up ?  [self parsedJSON:anObject] : [self serialized:anObject];
}

@end



#import <MPWFoundation/DebugMacros.h>

@interface MPWJSONCodingStoreTestClass : NSObject {}
@property (assign) long a,b;
@property (strong) id c;
@end
@implementation MPWJSONCodingStoreTestClass

-(void)writeOnJSONStream:(MPWJSONWriter*)aStream
{
    [aStream writeDictionaryLikeObject:self withContentBlock:^(id object, MPWJSONWriter *writer) {
        [writer writeInteger:self.a forKey:@"a"];
        [writer writeInteger:self.b forKey:@"b"];
        [writer writeString:self.c  forKey:@"c"];
    }];
 }

@end


@implementation MPWJSONConverterStore(testing) 

+(void)testConvertDictToJSONDown
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    MPWResource *json=[store mapObjectToStore:dicts forReference:nil];
    IDEXPECT( [[json rawData] stringValue], @"[{\"Key1\":\"Value1\",\"Key2\":15},{\"Key1\":\"Value2\",\"Key2\":42}]", @"json for dict");
}

+(void)testConvertJSONtoDictUp
{
    NSString *jsonSource=@"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]";
    NSArray *expected=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    NSArray *parsed=[store mapRetrievedObject:[jsonSource asData] forReference:nil];
    IDEXPECT(parsed, expected, @"dicts for JSON");
}

+(void)testConvertDictToJSONUp
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    store.up=true;
    MPWResource *json=[store mapRetrievedObject:dicts forReference:nil];
    IDEXPECT( [[json rawData] stringValue], @"[{\"Key1\":\"Value1\",\"Key2\":15},{\"Key1\":\"Value2\",\"Key2\":42}]", @"json for dict");
}

+(void)testConvertJSONtoDictDown
{
    NSString *jsonSource=@"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]";
    NSArray *expected=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    store.up=true;
    NSArray *parsed=[store mapObjectToStore:[jsonSource asData] forReference:nil];
    IDEXPECT(parsed, expected, @"dicts for JSON");
}


+(void)testConvertDictToJSONDownToSource
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWDictStore *d = [MPWDictStore store];
    MPWJSONConverterStore *store=[self storeWithSource:d];
    store[@"hi.json"]=dicts;
    IDEXPECT( [[d[@"hi.json"] rawData] stringValue], @"[{\"Key1\":\"Value1\",\"Key2\":15},{\"Key1\":\"Value2\",\"Key2\":42}]", @"json for dict");
}

+(void)testConvertJSONtoObjectUp
{
    NSString *jsonSource=@"[{\"a\":15, \"b\":13, \"c\":\"TestString1\"},{\"a\":42,\"b\":1, \"c\":\"TestString2\"}]";
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    [store setConverterClass:[MPWJSONCodingStoreTestClass class]];
    NSArray *parsed=[store mapRetrievedObject:[jsonSource asData] forReference:nil];
    INTEXPECT(parsed.count, 2, @"number of objects");
    MPWJSONCodingStoreTestClass *first,*last;
    first=parsed.firstObject;
    last=parsed.lastObject;
    INTEXPECT(first.a, 15, @"first.a");
    INTEXPECT(first.b, 13, @"first.b");
    IDEXPECT(first.c, @"TestString1", @"first.c");
    INTEXPECT(last.a, 42, @"last.a");
    INTEXPECT(last.b, 1, @"last.b");
    IDEXPECT(last.c, @"TestString2", @"last.c");
}

+(void)testConvertObjectToJSONDown
{
    MPWJSONCodingStoreTestClass *first=[[MPWJSONCodingStoreTestClass new] autorelease];
    MPWJSONCodingStoreTestClass *second=[[MPWJSONCodingStoreTestClass new] autorelease];
    first.a = 561;
    first.b = 42;
    first.c = @"Hello";
    second.a = 3;
    second.b = 0;
    second.c = @"World!";
    NSArray *objects=@[first,second];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    MPWResource *json=[store mapObjectToStore:objects forReference:nil];
    IDEXPECT( [[json rawData] stringValue], @"[{\"a\":561,\"b\":42,\"c\":\"Hello\"},{\"a\":3,\"b\":0,\"c\":\"World!\"}]", @"json for dict");
    json=[store mapObjectToStore:objects forReference:nil];
    IDEXPECT( [[json rawData] stringValue], @"[{\"a\":561,\"b\":42,\"c\":\"Hello\"},{\"a\":3,\"b\":0,\"c\":\"World!\"}]", @"json for dict");
}



+(NSArray*)testSelectors
{
   return @[
       @"testConvertDictToJSONDown",
       @"testConvertJSONtoDictUp",
       @"testConvertDictToJSONUp",
       @"testConvertJSONtoDictDown",
       @"testConvertDictToJSONDownToSource",
       @"testConvertJSONtoObjectUp",
       @"testConvertObjectToJSONDown",
			];
}

@end
