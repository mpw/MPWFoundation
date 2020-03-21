//
//  MPWTagHandler.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 2/19/08.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWSmallStringTable,MPWTagAction;

@interface MPWTagHandler : NSObject {
	id	exceptionMap;
	id	attributeMap;
	id	namespaceString;
    NSMutableDictionary *tagDict;
    MPWSmallStringTable *tagTable;
    MPWTagAction *undeclared;
    BOOL isCaseInsensitive;
}

-(void)setIsCaseInsensitive:(BOOL)caseSensitivty;
-(void)setExceptionMap:(NSDictionary*)map;
-(void)declareAttributes:(NSArray*)attributes;


-(void)setUndeclaredElementHandler:handler backup:backup;
-(void)setInvocation:anInvocation forElement:(NSString*)tagName;

-(void)initializeElementActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix;

-(void)initializeTagActionMapWithTags:(NSArray*)keys target:actionTarget prefix:prefix;



//---	getting FastInvocations for names


/*
-elementHandlerInvocationForCString:(const char*)cstr length:(int)len;
-tagHandlerInvocationForCString:(const char*)cstr length:(int)len;
*/
-namespaceString;
-(void)setNamespaceString:(id)newNamespaceString;
-actionForCString:(const char*)aCstring length:(long)len;


@end
