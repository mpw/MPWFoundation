//
//  MPWObjectStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 22.11.20.
//

#import "MPWObjectStore.h"
#import "AccessorMacros.h"
#import "MPWReference.h"

@interface MPWObjectStore()

@property (strong, nonatomic)  id object;

@end

@implementation MPWObjectStore

CONVENIENCEANDINIT( store, WithObject:(id)anObject)
{
    self=[super init];
    self.object=anObject;
    return self;
}

-(id)at:(id<MPWReferencing>)aReference
{
    return [self.object valueForKey:aReference.path];
}

-(void)at:(id<MPWReferencing>)aReference put:anObject
{
    return [self.object setValue:anObject forKey:aReference.path];
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

@implementation MPWObjectStore(testing) 

+(void)testInitializeObject
{
    MPWObjectStore *store=[self storeWithObject:@"hello"];
    IDEXPECT(store.object, @"hello", @"the object initialized the store with");
}

+(void)testListVars
{
    MPWObjectStoreSampleTestClass *tester=[[MPWObjectStoreSampleTestClass new] autorelease];
    MPWObjectStore *store=[self storeWithObject:tester];
    id <MPWReferencing> ref=[store referenceForPath:@"hi"];
    EXPECTNIL( store[ref],@"nothing there yet");
    tester.hi=@"there";
    IDEXPECT( store[ref], @"there", @"present in store after we put it in object");
    store[ref]=@"other";
    IDEXPECT( tester.hi, @"other", @"present in object aftere we put it there via store");
}

+(NSArray*)testSelectors
{
   return @[
       @"testInitializeObject",
       @"testListVars",
			];
}

@end
