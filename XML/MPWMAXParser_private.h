//
//  MPWMAXParser_private.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 22/04/2008.
//  Copyright 2008 Marcel Weiher. All rights reserved.
//

#import "MPWMAXParser.h"
#import "MPWXmlAttributes.h"
#import <AccessorMacros.h>

@class MPWTagAction,MPWTagHandler;

@interface MPWXMLAttributes(privateProtocol)

//---	append values with keys and tags

-(void)setValue:(id)anObject forAttribute:(id)aKey ;
-(void)setValueAndRelease:(id)anObject forAttribute:(id)aKey namespace:aNamespace;


-(id*)_pointerToObjects;

@end

typedef struct _NSXMLElementInfo {
	id			elementName;
	id			attributes;
	id			children;
	const char	*start;
	const char  *end;
	BOOL		isIncomplete;
	long			integerTag;
    long         fullyQualifiedLen;
    MPWTagAction *action;
    MPWTagHandler *handler;
} NSXMLElementInfo;

#define	INITIALTAGSTACKDEPTH 20

//#define DEOPTIMIZE_ALLOCATION 1

#if DEOPTIMIZE_ALLOCATION
#define MAKEDATA( dataStart, dataLength )   [NSData dataWithBytes:dataStart length:dataLength]
#else
#define MAKEDATA( start, lengthBytes )   initDataBytesLength( getData( dataCache, @selector(getObject)),@selector(reInitWithData:bytes:length:), data, start , lengthBytes )
#endif



/*  cached IMPs from SAX document handler methods */

#define	BEGINELEMENTSELECTOR		@selector(parser:didStartElement:namespaceURI:qualifiedName:attributes:)
#define	ENDELEMENTSELECTOR		    @selector(parser:didEndElement:namespaceURI:qualifiedName:)
#define	CHARACTERSSELECTOR		    @selector(parser:foundCharacters:)
#define	CDATASELECTOR				@selector(parser:foundCDATA:)


#define BEGINELEMENT(tag,namespaceURI,fullyQualified,attr)		beginElement(documentHandler, BEGINELEMENTSELECTOR ,self, tag,namespaceURI,fullyQualified,attr)
#define ENDELEMENT(tag,namespaceURI,fullyQualified)				endElement(documentHandler, ENDELEMENTSELECTOR , self,tag,namespaceURI,fullyQualified )

#define RECORDSCANPOSITION( start, length )			lastGoodPosition=start+length

#if DEOPTIMIZE_ALLOCATION
#define TAGFORCSTRING( cstr, cstrlen)   [[[NSString alloc] initWithBytes:cstr length:cstrlen encoding:NSUTF8StringEncoding] autorelease]
#else
#define TAGFORCSTRING( cstr, cstrlen)   MAKEDATA( cstr, cstrlen )
#endif


#define	CHARACTERDATAALLOWED		characterDataAllowed( self, @selector(characterDataAllowed:), self )
#define	CHARACTERS( c )				characters( characterHandler , CHARACTERSSELECTOR,self, c )
#define	CDATA( c )					cdata( characterHandler ,CDATASELECTOR,self, c )


#define POPTAG						( [((NSXMLElementInfo*)_elementStack)[--tagStackLen].elementName release])
#define PUSHTAG(aTag) {\
    if ( tagStackLen > tagStackCapacity ) {\
        [self _growTagStack:tagStackCapacity * 2];\
    }\
    ((NSXMLElementInfo*)_elementStack)[tagStackLen++].elementName=[aTag retain];\
}

#define CURRENTOBJECT  				[self currentObject]
#define PUSHOBJECT(anObject, key, aNamespace) {\
    [self pushObject:anObject forKey:key withNamespace:aNamespace];\
}
#define CURRENTELEMENT  			(((NSXMLElementInfo*)_elementStack)[tagStackLen-1] )
#define CURRENTTAG  				((tagStackLen > 0) ? CURRENTELEMENT.elementName : nil)
#define CURRENTINTEGERTAG 			((tagStackLen > 0) ? CURRENTELEMENT.integerTag : -3)



@interface MPWMAXParser(private)

objectAccessor_h(NSError*, parserError, setParserError )

-(void)_growTagStack:(long)newCapacity;
-currentTag;
-(void)pushTag:aTag;
-(void)popTag;
-getTagForCString:(const char*)cstr length:(int)len;
-currentObject;
-(void)handleNameSpaceAttribute:name withValue:value;

-(void)setScanner:newScanner;
-(void)setAutotranslateUTF8:(BOOL)shouldTranslate;

-(void)flushPureSpace;
-(void)clearAttributes;
-(void)_setAttributes:newAttributes;

-(void)setDelegate:newDelegate;

-(void)rebuildPrefixHandlerMap;
-(id)_attributes;
-_fullTagStackString;

-(void)setData:newData;

-(BOOL)makeText:(const char*)start length:(long)len firstEntityOffset:(long)entityOffset;
-(void)pushObject:anObject forKey:aKey withNamespace:aNamespace;
-(long)dataEncoding;
-(void)setDataEncoding:(long)newEncoding;
-(BOOL)parseSource:(NSEnumerator*)source;
-htmlAttributeLowerCaseNamed:(NSString*)lowerCaseAttributeName;
-(BOOL)handleMetaTag;
-currentChildren;

@end
