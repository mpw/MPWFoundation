//
//  MPWReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWWriteStream.h>
#import "MPWReference.h"
#import <MPWAbstractStore.h>
#import "MPWGenericIdentifier.h"
#import <AccessorMacros.h>
#import "MPWPathRelativeStore.h"
#import "NSObjectFiltering.h"

@implementation MPWReference


CONVENIENCEANDINIT( binding, WithReference:(MPWGenericIdentifier*)ref inStore:(MPWAbstractStore*)aStore)
{
    self=[super init];
    self.identifier=[ref asReference];
    self.store=aStore;
    return self;
}

-value
{
    return [self.store at:self.identifier];
}

-(void)setValue:newValue
{
    [self.store at:self.identifier put:newValue];
}

-post:newValue
{
    return [self.store at:self.identifier post:newValue];
}


-(void)delete
{
    [self.store deleteAt:self.identifier];
}

-(BOOL)hasChildren
{
    return [self.store hasChildren:self.identifier];
}

-(NSArray*)children
{
    return [[[self class] collect] bindingWithReference:[[self.store childrenOfReference:self.identifier] each] inStore:self.store];
}

-(NSURL*)URL
{
    return [self.store URLForReference:self.identifier];
}

-(NSString*)path
{
    return [(MPWGenericIdentifier*)self.identifier path];
}

-(id <MPWIdentifying>)asReference
{
    return [self identifier];
}

-(MPWPathRelativeStore*)asScheme
{
    return [self.store relativeStoreAt:self.identifier];
}

-(NSArray*)pathComponents
{
    return self.identifier.pathComponents;
}

-(NSArray*)relativePathComponents
{
    return self.identifier.pathComponents;
}

-(NSString*)schemeName
{
    return self.identifier.schemeName;
}

-(void)setSchemeName:(NSString*)newName
{
    self.identifier.schemeName=newName;
}

- (instancetype)referenceByAppendingReference:(id<MPWIdentifying>)other {
    return [[self class] bindingWithReference:[(MPWGenericIdentifier*)[self identifier] referenceByAppendingReference:(MPWGenericIdentifier*)other] inStore:self.store];
}

-(instancetype)div:(MPWReference*)other
{
    return [self referenceByAppendingReference:other];
}


-(void)writeObject:anObject
{
    [self setValue:anObject];
}

-(void)writeTarget:sender
{
    [self writeObject:[sender objectValue]];
}

-writeStream
{
    return [self.store writeStreamAt:self.identifier];
}


-(void)traverse:(id <Streaming>)target
{
    [target writeObject:self];
    if ( [self hasChildren]) {
        [[[self children] do] traverse:target];
    }
}

-copyWithZone:(NSZone*)aZone
{
    return [[[self class] allocWithZone:aZone] initWithReference:[[(id <NSCopying>)(self.identifier) copyWithZone:aZone] autorelease] inStore:self.store];
}

-(BOOL)isBound
{
    return self.value != nil;
}

-ifBound:aBlock
{
    return [self isBound] ? [aBlock value] : nil;
}

-ifNotBound:aBlock
{
    return ![self isBound] ? [aBlock value] : nil;
}

-(BOOL)isAffectedBy:(MPWReference*)other
{
    return [[self asReference] isAffectedBy:[other asReference]];
}
-(BOOL)hasTrailingSlash
{
    return [self.identifier hasTrailingSlash];
}

-(void)dealloc
{
    [(id)_identifier release];
    [_store release];
    [super dealloc];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: reference: '%@' store: %@>",[self className],self,self.identifier,self.store];
}

@end

#import "DebugMacros.h"

@implementation MPWReference(tests)

+(void)testAsScheme
{
    MPWAbstractStore *s=[MPWAbstractStore store];
    MPWReference *binding=[s bindingForReference:@"hello/world" inContext:nil];
    MPWPathRelativeStore* relativeStore = (MPWPathRelativeStore*)[binding asScheme];

    IDEXPECT( [relativeStore mapReference:@"base"], @"hello/world/base", @"mapped from scheme");
}

+(void)testCanSetIdentifier
{
    MPWReference *ref=[self new];
    [ref setIdentifier:@"someIdentifier"];
}

+(NSArray<NSString*>*)testSelectors
{
    return @[
        @"testAsScheme",
        @"testCanSetIdentifier",
    ];
}

@end
