//
//  MPWTagAction.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWTagAction.h"
#import <AccessorMacros.h>
#import "MPWFastInvocation.h"

@interface MPWTagAction(testingSupport)

+defaultElement:childen attributes:children parser:parser;


@end

@implementation MPWTagAction

objectAccessor(NSString*, tagName, setTagName)
objectAccessor(NSString*, mappedName, setMappedName)
objectAccessor(NSString*, tagNamespace, setTagNamespace)
objectAccessor(NSString*, namespacePrefix, setNamespacePrefix)
objectAccessor(MPWFastInvocation*, tagAction, setTagAction)
objectAccessor(MPWFastInvocation*, elementAction, setElementAction)


-initWithTagName:(NSString*)tag
{
    self=[super init];
    [self setTagName:tag];
    [self setNamespacePrefix:@""];
    return self;
}

+tagActionWithName:(NSString*)tag
{
    return [[[self alloc] initWithTagName:tag] autorelease];
}

+undeclaredElementAction
{
    return [self tagActionWithName:@"undeclared"];
}


-(NSString*)mappedOrNormalTagName
{
    id result=[self mappedName];
    if ( !result){
        result=[self tagName];
    }
    return result;
}

-(SEL)elementSelector
{
    return NSSelectorFromString( [[[self mappedOrNormalTagName] stringByAppendingString:namespacePrefix ] stringByAppendingString:@"Element:attributes:parser:"]  );
} 

-(SEL)tagSelector
{
    return NSSelectorFromString( [[self mappedOrNormalTagName] stringByAppendingString:@"Tag:parser:"]  );
}

-(SEL)defaultElementSelector
{
	return @selector(defaultElement:attributes:parser:);
}

-(BOOL)targetRespondsToElementSelector:aTarget
{
    return [aTarget respondsToSelector:[self elementSelector]];
}

-(SEL)elementSelectorForTarget:aTarget
{
    return [self targetRespondsToElementSelector:aTarget] ? [self elementSelector]:[self defaultElementSelector];
}

-(MPWFastInvocation*)createElementInvocationWithTarget:primaryTarget backup:backupTarget
{
    MPWFastInvocation *invocation=[[[MPWFastInvocation alloc] init] autorelease];
    id target=primaryTarget;
    BOOL primaryHasSelector=[self targetRespondsToElementSelector:primaryTarget];
    BOOL backupHasSelector=[self targetRespondsToElementSelector:backupTarget];
    BOOL primaryHasDefault=[primaryTarget respondsToSelector:[self defaultElementSelector]];
    if ( !primaryHasSelector) {
        if ( backupHasSelector || !primaryHasDefault ) {
            target=backupTarget;
        }
    }
    [invocation setTarget:target];
    [invocation setSelector:[self elementSelectorForTarget:target]];
    [invocation setUseCaching:YES];
    return invocation;
}

-(void)setElementInvocationForTarget:primaryTarget backup:backupTarget
{
    [self setElementAction:[self createElementInvocationWithTarget:primaryTarget backup:backupTarget]];
}

-(void)setTagInvocationForTarget:primaryTarget
{
    MPWFastInvocation *invocation=[[[MPWFastInvocation alloc] init] autorelease];
    [invocation setTarget:primaryTarget];
    [invocation setSelector:[self tagSelector]];
    [invocation setUseCaching:YES];
    [self setTagAction:invocation];
}



-(void)dealloc
{
    [tagName release];
    [mappedName release];
    [tagNamespace release];
    [tagAction release];
    [elementAction release];
    [super dealloc];
}

@end
#import "DebugMacros.h"

@implementation MPWTagAction(testing)

+helloElement:childen attributes:children parser:parser
{
    return [@"54" retain];
}

+defaultElement:childen attributes:children parser:parser
{
    return [@"default" retain];
}


+(void)testBasicTagName
{
    IDEXPECT([[self tagActionWithName:@"hello"] tagName],@"hello",@"tag name");
}

+(void)testElementSelectorName
{
    id action=[self tagActionWithName:@"hello"];
    IDEXPECT( NSStringFromSelector([action elementSelector]),@"helloElement:attributes:parser:", @"element selector for hello");
}

+(void)testTagSelectorName
{
    id action=[self tagActionWithName:@"hello"];
    IDEXPECT( NSStringFromSelector([action tagSelector]),@"helloTag:parser:", @"element selector for hello");
}

+(void)testMappedSelectorName
{
    id action=[self tagActionWithName:@"hello"];
    [action setMappedName:@"hi"];
    IDEXPECT( NSStringFromSelector([action tagSelector]),@"hiTag:parser:", @"element selector for hello mapped to hi");
}

+(void)testDefaultSelector
{
    id action=[self tagActionWithName:@"hello"];
    IDEXPECT( NSStringFromSelector([action defaultElementSelector]),@"defaultElement:attributes:parser:", @"element selector for hello mapped to hi");
}

+(void)testTargetRespondsToElementSelector
{
    id action1=[self tagActionWithName:@"hello"];
    id action2=[self tagActionWithName:@"hi"];
    EXPECTTRUE([action1 targetRespondsToElementSelector:self], @"responds to helloElemenet")
    EXPECTFALSE([action2 targetRespondsToElementSelector:self], @"responds to hiElemenet")
}

+(void)testElementSelectorOrDefaultSelectorIfTargetDoesntRespond
{
    id action1=[self tagActionWithName:@"hello"];
    id action2=[self tagActionWithName:@"hi"];
    
    IDEXPECT( NSStringFromSelector([action1 elementSelectorForTarget:self]),@"helloElement:attributes:parser:", @"exists, not defaulted");
    IDEXPECT( NSStringFromSelector([action2 elementSelectorForTarget:self]),@"defaultElement:attributes:parser:", @"does not exist, defaulted");
}

+(void)testCreateElementInvocationWithBackupTargetAndDefaultSelector
{
    id action1=[self tagActionWithName:@"hello"];
    id action2=[self tagActionWithName:@"hi"];
    
    MPWFastInvocation *i1=[action1 createElementInvocationWithTarget:self backup:action1];
    IDEXPECT( NSStringFromSelector([i1 selector]),@"helloElement:attributes:parser:" , @"nondefaulted selector");
    IDEXPECT([i1 target], self, @"original target");
    MPWFastInvocation *i2=[action1 createElementInvocationWithTarget:action1 backup:self];
    IDEXPECT( NSStringFromSelector([i2 selector]),@"helloElement:attributes:parser:" , @"nondefaulted selector because backup object handles exact element");
    IDEXPECT([i2 target], self, @"backup target");
    MPWFastInvocation *i3=[action2 createElementInvocationWithTarget:self backup:action1];
    IDEXPECT( NSStringFromSelector([i3 selector]),@"defaultElement:attributes:parser:" , @"nondefaulted selector because backup object handles exact element");
    IDEXPECT([i3 target], self, @"primary target with default selector");
    MPWFastInvocation *i4=[action2 createElementInvocationWithTarget:action1 backup:self];
    IDEXPECT( NSStringFromSelector([i4 selector]),@"defaultElement:attributes:parser:" , @"backup target, default selector");
    IDEXPECT([i4 target], self, @"backup target, default selector");
}

+(void)testUndeclaredElementExistsAndHasElementSelector
{
    id action=[self undeclaredElementAction];
    IDEXPECT( NSStringFromSelector([action elementSelector]),@"undeclaredElement:attributes:parser:", @"undeclared elemenet selector");
    
}

+(void)testSetTagInvocation
{
    id action=[self undeclaredElementAction];
    EXPECTNIL([action tagAction], @"tag action before I set it up");
    [action setTagInvocationForTarget:self];
    IDEXPECT(NSStringFromSelector([[action tagAction] selector]), @"undeclaredTag:parser:", @"selector of tag action");
    IDEXPECT([[action tagAction] target], self, @"target of tag action");
}


+(void)testSetElementInvocation
{
    id action1=[self tagActionWithName:@"hello"];
    [action1 setElementInvocationForTarget:self backup:action1];
    MPWFastInvocation *i1=[action1 elementAction];
    IDEXPECT( NSStringFromSelector([i1 selector]),@"helloElement:attributes:parser:" , @"nondefaulted selector");
    IDEXPECT([i1 target], self, @"original target");
}

+(void)testPrefix
{
    id action1=[self tagActionWithName:@"hello"];
    [action1 setNamespacePrefix:@"Namespace"];
    IDEXPECT( NSStringFromSelector([action1 elementSelector]),@"helloNamespaceElement:attributes:parser:" , @"prefixed selector");
}

+testSelectors
{
    return @[
    @"testBasicTagName",
    @"testTagSelectorName",
    @"testElementSelectorName",
    @"testMappedSelectorName",
    @"testDefaultSelector",
    @"testTargetRespondsToElementSelector",
    @"testElementSelectorOrDefaultSelectorIfTargetDoesntRespond",
    @"testCreateElementInvocationWithBackupTargetAndDefaultSelector",
    @"testUndeclaredElementExistsAndHasElementSelector",
    @"testSetTagInvocation",
    @"testSetElementInvocation",
    @"testPrefix",
    ];
}


@end
