//
//  MPWObjectStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.11.20.
//

#import "MPWPropertyStore.h"
#import "AccessorMacros.h"
#import "MPWIdentifier.h"
#import "MPWDirectoryReference.h"
#import "NSObjectFiltering.h"
#import <objc/runtime.h>
#import "MPWPropertyBinding.h"


@interface MPWPropertyStore()



@end

@implementation MPWPropertyStore
{
    MPWDirectoryReference *listOfProperties;
}

-(id)object
{
    return self.baseObject;
}

lazyAccessor(MPWDirectoryReference*, listOfProperties, setListOfProperties, computeListOfProperties)

CONVENIENCEANDINIT( store, WithObject:(id)anObject)
{
    self=[super init];
    self.baseObject=anObject;
    return self;
}

-(void)addPropertyNamesOfClass:(Class)c toArray:(NSMutableArray*)propertyNames
{
    unsigned int count=0;
    objc_property_t *props=class_copyPropertyList(c, &count);
    for (int i=0;i<count;i++) {
        NSString *name = @(property_getName(props[i]));
        if (![propertyNames containsObject:name]) {
            [propertyNames addObject:name];
        }
    }
}

-(NSArray*)propertyNames
{
    Class c = object_getClass(self.object);
    Class stopClass = [NSObject class];
    NSMutableArray *propertyNames=[NSMutableArray array];
    while ( c && c!=stopClass) {
        [self addPropertyNamesOfClass:c toArray:propertyNames];
        c = class_getSuperclass(c);
    }
    return propertyNames;
}

-(MPWDirectoryReference*)computeListOfProperties
{
    NSArray *refs = (NSArray*)[[self collect] referenceForPath:[[self propertyNames] each]];
    return [[[MPWDirectoryReference alloc] initWithContents:refs] autorelease];
}

-(id)at:(id<MPWIdentifying>)aReference
{
    NSString *path=aReference.path;
    if ( [path isEqual:@"."] || path.length==0 || [aReference isRoot] ) {
        return [self listOfProperties];
    } else {
        return [self.object valueForKey:aReference.path];
    }
}

-(void)at:(id<MPWIdentifying>)aReference put:anObject
{
    return [self.object setValue:anObject forKey:aReference.path];
}


-(MPWReference*)bindingForReference_disabled:(id)aReference inContext:(id)aContext
{
    MPWPropertyBinding *accessor=[[[MPWPropertyBinding alloc] initWithName:[aReference path]] autorelease];
    [accessor bindToTarget:self.object];
    return (MPWReference*)accessor;
}

-(void)dealloc
{
    [listOfProperties release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@interface MPWObjectStoreSampleTestClass: NSObject {}
@property (strong,nonatomic) NSString *hi;
@end
@implementation MPWObjectStoreSampleTestClass
-(void)deallooc {
    [_hi release];
    [super dealloc];
}
@end

@implementation MPWPropertyStore(testing) 

+(void)testInitializeObject
{
    MPWPropertyStore *store=[self storeWithObject:@"hello"];
    IDEXPECT(store.object, @"hello", @"the object initialized the store with");
}

+(void)testAccessVars
{
    MPWObjectStoreSampleTestClass *tester=[[MPWObjectStoreSampleTestClass new] autorelease];
    MPWPropertyStore *store=[self storeWithObject:tester];
    id <MPWIdentifying> ref=[store referenceForPath:@"hi"];
    EXPECTNIL( store[ref],@"nothing there yet");
    tester.hi=@"there";
    IDEXPECT( store[ref], @"there", @"present in store after we put it in object");
    store[ref]=@"other";
    IDEXPECT( tester.hi, @"other", @"present in object aftere we put it there via store");
}

+(void)testListVars
{
    MPWObjectStoreSampleTestClass *tester=[[MPWObjectStoreSampleTestClass new] autorelease];
    MPWPropertyStore *store=[self storeWithObject:tester];
    MPWDirectoryReference *proplist=[store at:[store referenceForPath:@"."]];
    INTEXPECT( proplist.contents.count,1,@"");

}

+(void)testSimpleReadBinding
{
    MPWObjectStoreSampleTestClass *tester=[[MPWObjectStoreSampleTestClass new] autorelease];
    MPWPropertyStore *store=[self storeWithObject:tester];
    id <MPWIdentifying> ref=[store referenceForPath:@"hi"];
    tester.hi=@"there";
    MPWReference *binding=[store bindingForReference:ref inContext:nil];
    NSLog(@"binding: %@",binding);
    IDEXPECT( [binding value], @"there",@"read via binding");

}

+(NSArray*)testSelectors
{
   return @[
       @"testInitializeObject",
       @"testAccessVars",
       @"testListVars",
       @"testSimpleReadBinding",
			];
}

@end
