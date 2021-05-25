//
//  MPWJSONConverterStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.05.21.
//

#import "MPWJSONConverterStore.h"

@interface MPWJSONConverterStore()

@property (nonatomic, strong) MPWJSONWriter *writer;
@property (nonatomic, strong) MPWMASONParser *reader;

@end


@implementation MPWJSONConverterStore

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource
{
    self=[super initWithSource:newSource];
    self.writer = [MPWJSONWriter stream];
    self.reader = [MPWMASONParser parser];
    return self;
}

-(id)parsedJSON:(NSData*)json
{
    [self.writer setTarget:[NSMutableData data]];
    [self.writer writeObject:json];
    return self.writer.target;
}

-(NSData*)serialized:(id)anObject
{
    return [self.reader parsedData:anObject];
}

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.toJSONUp ? [self parsedJSON:anObject] : [self serialized:anObject];
}

-(id)mapObjectToStore:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.toJSONUp ? [self serialized:anObject] : [self parsedJSON:anObject];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWJSONConverterStore(testing) 

+(void)testConvertDictToJSONDown
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    NSData *json=[store mapObjectToStore:dicts forReference:nil];
    IDEXPECT( [json stringValue], @"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]", @"json for dict");
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
    store.toJSONUp=true;
    NSData *json=[store mapRetrievedObject:dicts forReference:nil];
    IDEXPECT( [json stringValue], @"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]", @"json for dict");
}

+(void)testConvertJSONtoDictDown
{
    NSString *jsonSource=@"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]";
    NSArray *expected=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    store.toJSONUp=true;
    NSArray *parsed=[store mapObjectToStore:[jsonSource asData] forReference:nil];
    IDEXPECT(parsed, expected, @"dicts for JSON");
}

+(NSArray*)testSelectors
{
   return @[
       @"testConvertDictToJSONDown",
       @"testConvertJSONtoDictUp",
       @"testConvertDictToJSONUp",
       @"testConvertJSONtoDictDown",
			];
}

@end
