//
//  MPWTagHandler.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import "MPWTagHandler.h"
#import "MPWTagAction.h"
#import <objc/objc.h>
#import <AccessorMacros.h>
#import "MPWCaseInsensitiveSmallStringTable.h"
#import "MPWFastInvocation.h"

@implementation MPWTagHandler

objectAccessor(NSDictionary*, exceptionMap, setExceptionMap )
idAccessor( attributeMap, setAttributeMap )
idAccessor( namespaceString, setNamespaceString )
objectAccessor(NSMutableDictionary*, tagDict, setTagDict)
objectAccessor(MPWSmallStringTable*, tagTable, setTagTable)
objectAccessor(MPWTagAction*, undeclared, setUndeclared )
boolAccessor(isCaseInsensitive, setIsCaseInsensitive)
-init
{
    self=[super init];
    [self setTagDict:[NSMutableDictionary dictionaryWithCapacity:5]];
    return self;
}

+tagHandler
{
    return [[[self alloc] init] autorelease];
}

-(void)addTag:(NSString*)tag
{
    if ( ![[self tagDict] objectForKey:tag]) {
        MPWTagAction *action=[[[MPWTagAction alloc] initWithTagName:tag] autorelease];
        [action setMappedName:[[self exceptionMap] objectForKey:tag]];
        [[self tagDict] setObject:action forKey:tag];
    }
}

-(MPWTagAction*)tagForKey:(NSString*)tag
{
    return [[self tagDict] objectForKey:tag];
}



-(void)setUndeclaredElementHandler:handler backup:backup
{
    MPWTagAction *u = [MPWTagAction undeclaredElementAction];
    [u setElementInvocationForTarget:handler backup:backup];
    [[self tagDict] setObject:u forKey:[u tagName]];
    [u setTagName:nil];
    [self setUndeclared:u];
    
}



-(void)declareAttributes:(NSArray*)attributes 
{
	[self setAttributeMap:[[[MPWSmallStringTable alloc] initWithKeys:attributes values:attributes] autorelease]];
}


-description
{
	return [NSString stringWithFormat:@"<%@/%p:  %@>",[self class],self,namespaceString];
}

-(void)dealloc
{
//    NSLog(@"tag handler dealloc");
	[exceptionMap release];
	[attributeMap release];
	[super dealloc];
//    NSLog(@"tag handler did dealloc");
}

-actionForCString:(const char*)aCstring length:(long)len
{
    if (!tagTable) {
        [self buildLookupTables];
    }
    return OBJECTFORSTRINGLENGTH(tagTable, (char*)aCstring, (int)len);
}

-actionForCString:(const char*)aCstring
{
    return [self actionForCString:aCstring length:strlen(aCstring)];
}

-getTagForCString1:(const char*)cstr length:(int)len
{
    return [[self actionForCString:cstr length:len] tagName];
}

-elementHandlerInvocationForCString1:(const char*)cstr length:(int)len
{
    return [[self actionForCString:cstr length:len] elementAction];
}

-tagHandlerInvocationForCString1:(const char*)cstr length:(int)len
{
    return [[self actionForCString:cstr length:len] tagAction];
}


-(void)buildLookupTables
{
    Class tableClass= isCaseInsensitive ? [MPWCaseInsensitiveSmallStringTable class] : [MPWSmallStringTable class];
    NSArray *keys=[[self tagDict] allKeys];
    NSArray *values=[[self tagDict] objectsForKeys:keys notFoundMarker:@""]; //[[[[self tagDict] collect] objectForKey:[keys each]]];
    MPWSmallStringTable *stringTable = [[[tableClass alloc] initWithKeys:keys values:values] autorelease];
    [stringTable setDefaultValue:[self undeclared]];
    [self setTagTable:stringTable];
}

-(void)initializeElementActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix
{
    for ( NSString *key in keys ){
        [self addTag:key];
        MPWTagAction *action=[self tagForKey:key];
        [action setNamespacePrefix:prefix];
        [action setElementInvocationForTarget:actionTarget backup:nil];
        
    }
}

-(void)initializeTagActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix
{
    for ( NSString *key in keys ){
        [self addTag:key];
        MPWTagAction *action=[self tagForKey:key];
        [action setTagInvocationForTarget:actionTarget];
        
    }
}

-(void)setInvocation:anInvocation forElement:(NSString*)tagName
{
    MPWTagAction* action = [[self tagDict] objectForKey:tagName];
    [action setElementAction:anInvocation];
    
}


@end


@interface MPWTagHandlerTesting : NSObject {}

@end 

#import "DebugMacros.h"

@implementation MPWTagHandlerTesting

+dummyElement:children attributes:attrs parser:paser
{
	return @"53";
}

+dummyNamespaceElement:children attributes:attrs parser:paser
{
	return @"62";
}

+dummyTag:tag parser:paser
{
    return @"";
}

+(void)testElementHandlerForCString
{
	id handler=[[[MPWTagHandler alloc] init] autorelease];
	id invocation;
	[handler initializeElementActionMapWithTags:[NSArray arrayWithObjects:@"dummy",nil] target:self prefix:@""];
	invocation = [[handler actionForCString:"dummy" length:5] elementAction];
    EXPECTNOTNIL(invocation, @"invocation");
	IDEXPECT( [invocation resultOfInvoking], @"53", @"result of invoking");
    
}

+(void)testElementHandlerForCStringWithPrefix
{
	id handler=[[[MPWTagHandler alloc] init] autorelease];
	id invocation;
	[handler initializeElementActionMapWithTags:[NSArray arrayWithObjects:@"dummy",nil] target:self prefix:@"Namespace"];
	invocation = [[handler actionForCString:"dummy" length:5] elementAction];
    EXPECTNOTNIL(invocation, @"invocation");
	IDEXPECT( [invocation resultOfInvoking], @"62", @"result of invoking");
    
}

+(void)testTagHandlerCreatesActions
{
	id handler=[MPWTagHandler tagHandler];
    [handler addTag:@"hello"];
    EXPECTNOTNIL([handler tagForKey:@"hello"], @"hello retrieved");
}

+(void)testCreateCstringLookupFromActionsDict
{
	id handler=[MPWTagHandler tagHandler];
    [handler addTag:@"hello"];
    MPWTagAction *action=[handler tagForKey:@"hello"];
    EXPECTNOTNIL(action, @"hello retrieved");
    MPWTagAction *action1=[handler actionForCString:"hello"];
    EXPECTNOTNIL(action1, @"after setup yet");
    IDEXPECT(action, action1, @"retrieved via base dict and small string table");
    EXPECTNIL([handler actionForCString:"hello1"], @"hello1 should not be in table");
}

+(void)testMakeElementActions
{
	id handler=[MPWTagHandler tagHandler];
	[handler initializeElementActionMapWithTags:[NSArray arrayWithObjects:@"dummy",nil] target:self prefix:@""];
    MPWTagAction *dummyAction=[handler tagForKey:@"dummy"];
    EXPECTNOTNIL(dummyAction, @"dummy action retrieved from nsdict");
    IDEXPECT([dummyAction tagName], @"dummy", @"retrieved tag name");
    MPWFastInvocation *elementInvocation=[dummyAction elementAction];
    EXPECTNOTNIL(elementInvocation, @"element action");
    IDEXPECT(NSStringFromSelector([elementInvocation selector]),@"dummyElement:attributes:parser:",@"selector");
    IDEXPECT([elementInvocation target],self,@"target");
    MPWTagAction *action1=[handler actionForCString:"dummy"];
    MPWFastInvocation *invocation1=[action1 elementAction];
    IDEXPECT(NSStringFromSelector([invocation1 selector]),@"dummyElement:attributes:parser:",@"selector");
}

+(void)testMakeTagActions
{
	id handler=[MPWTagHandler tagHandler];
	[handler initializeTagActionMapWithTags:[NSArray arrayWithObjects:@"dummy",nil] target:self prefix:@""];
    MPWTagAction *action1=[handler actionForCString:"dummy"];
    MPWFastInvocation *invocation1=[action1 tagAction];
    IDEXPECT(NSStringFromSelector([invocation1 selector]),@"dummyTag:parser:",@"selector");
}



+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
            @"testElementHandlerForCString",
            @"testElementHandlerForCStringWithPrefix",
            @"testTagHandlerCreatesActions",
            @"testCreateCstringLookupFromActionsDict",
            @"testMakeElementActions",
            @"testMakeTagActions",
				nil];
}	


@end

