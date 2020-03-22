//
//  MPWXmlParserTesting.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 10/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWXmlParserTesting.h"
#import "MPWXmlParser.h"
#import "MPWMAXParser_private.h"
#import "MPWMessageCatcher.h"
#import "MPWSubData.h"
#import "DebugMacros.h"
#import "NSBundleConveniences.h"
#import "NSObjectAdditions.h"

@interface EmptySAXClient : NSObject

@end

@implementation EmptySAXClient

-(void)parserDidStartDocument:parser {}
-(void)parserDidEndDocument:parser{}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {}
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)data {}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {}
-(void)parser:aParser didStartMappingPrefix:aPrefix toURI: uri {}
-(void)parser:aParser didEndMappingPrefix:aPrefix {}
-(NSData*)parser:aParser resolveExternalEntityName:name systemID:systemId { return nil;}

-(void)characters:characterData{}
-(void)cdata:cdataData{}
-(void)setDocumentLocator:locator{}

@end

@implementation MPWXmlParserTesting

idAccessor( messages, setMessages )
boolAccessor( shouldAbort, setShouldAbort )
idAccessor( totalText, setTotalText )
idAccessor( nonWSCharSet, setNonWSCharSet )

-init
{
	self=[super init];
	[self setMessages:[NSMutableArray array]];
	[self setTotalText:[NSMutableString string]];
	[self setShouldAbort:NO];
	[self setNonWSCharSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]];
	return self;
}

-xxxMesssages {
	return messages;
}

-(long)xxxMessageCount {
	return [messages count];
}

-xxxMessageNameAtIndex:(int)anIndex
{
	return [[messages objectAtIndex:anIndex] objectAtIndex:0];
}

-xxxMessageArgumentNumber:(int)argIndex atIndex:(int)messageIndex
{
	return [[messages objectAtIndex:messageIndex] objectAtIndex:argIndex];
}

-(void)parserDidStartDocument:parser {
	if ( [self shouldAbort] ) {
		[parser abortParsing];
	}
	[messages addObject:[NSArray arrayWithObject:NSStringFromSelector( _cmd )]];
}
-(void)parserDidEndDocument:parser{
	[messages addObject:[NSArray arrayWithObject:NSStringFromSelector( _cmd )]];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if ( [[[messages lastObject] objectAtIndex:0] isEqual:NSStringFromSelector( _cmd )] ) {
		string=[[[messages lastObject] objectAtIndex:1] stringByAppendingString:string];
		[messages removeLastObject];
	}
	[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),string,@"",@"",nil]];
	NSRange range = [string rangeOfCharacterFromSet:[self nonWSCharSet]];
	
	if (range.location != NSNotFound) {
		[totalText appendString:string];
	}
	
}
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)data {
	NSString *str=(NSString*)data;
	if ( [[[messages lastObject] objectAtIndex:0] isEqual:NSStringFromSelector( _cmd )] ) {
		str=[[[messages lastObject] objectAtIndex:1] stringByAppendingString:str];
		[messages removeLastObject];
	}
	[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),str,@"",@"",nil]];
	
}

#define NONNIL( x )  ( ((NSString*)x)?((NSString*)x):((NSString*)@""))

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),
								elementName,NONNIL(namespaceURI) ,NONNIL(qName),NONNIL(attributeDict),nil]];

}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
		[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),
								elementName,NONNIL(namespaceURI),NONNIL(qName),@"",nil]];

}
-(void)parser:aParser didStartMappingPrefix:aPrefix toURI: uri {
		[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),
								aPrefix,uri,nil]];

}
-(void)parser:aParser didEndMappingPrefix:aPrefix {
		[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),
								aPrefix,nil]];

}
-(NSData*)parser:aParser resolveExternalEntityName:name systemID:systemId {
		[messages addObject:[NSArray arrayWithObjects:NSStringFromSelector( _cmd ),
								name,systemId,nil]];
	return nil;
}

#if EMULATE_JAVA_SAX
-(void)characters:(char*)base from:(unsigned)start length:(unsigned)length{}
-(void)ignorableWhitespace:(char*)base from:(unsigned)start length:(unsigned)length{}
-(void)processingInstruction:target data:data{}
#else
-(void)characters:characterData{}
-(void)cdata:cdataData{}
#endif
-(void)setDocumentLocator:locator{}


#define EXPECTMESSAGEAT( catcher, index, message )      IDEXPECT( [catcher xxxMessageNameAtIndex:index],message , @"" )
#define EXPECTMESSAGEANDARGAT( catcher, index, message, arg )      IDEXPECT( [[catcher xxxMessageNameAtIndex:index] stringByAppendingString:[catcher xxxMessageArgumentNumber:1 atIndex:index]],[message stringByAppendingString:arg] , @"" )

#define EXPECTSTARTELEMENTAT( catcher, index, tag )		EXPECTMESSAGEANDARGAT( catcher, index, @"parser:didStartElement:namespaceURI:qualifiedName:attributes:", tag )
// EXPECTMESSAGEAT( catcher, index,  ); IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:index], tag , @"" )
#define ATTRIBUTES( catcher, index )					[catcher xxxMessageArgumentNumber:4 atIndex:index]
#define EXPECTATTRIBUTEAT( catcher, index, attributeName, attributeValue )			IDEXPECT( [ATTRIBUTES(  catcher, index)  objectForKey:attributeName] , attributeValue, @"attribute " )
#define EXPECTENDELEMENTAT( catcher, index, tag )		EXPECTMESSAGEANDARGAT( catcher, index, @"parser:didEndElement:namespaceURI:qualifiedName:", tag )
#define EXPECTCHARACTERS( catcher, index, characters )	EXPECTMESSAGEANDARGAT( catcher, index, @"parser:foundCharacters:", characters )
#define EXPECTCDATA( catcher, index, characters )	EXPECTMESSAGEANDARGAT( catcher, index, @"parser:foundCDATA:", characters )
#define EXPECTENTITY( catcher, index, entityName )		EXPECTMESSAGEANDARGAT( catcher, index, @"parser:resolveExternalEntityName:systemID:", entityName )
//#define EXPECTENDELEMENTAT( catcher, index, tag )		EXPECTMESSAGEAT( catcher, index, @"parser:didEndElement:namespaceURI:qualifiedName:" ); IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:index], tag , @"" )

+xmlResourceWithName:(NSString*)name
{
	id resource = [self resourceWithName:name type:@"xml"];
    EXPECTNOTNIL(resource,name);
    return resource;
}

+catcher
{
	return [[[self alloc] init] autorelease];
}

+parser
{
	return [MPWSAXParser parser];
}

+(void)testBasicSaxParse
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"test1"];
    INTEXPECT( [xmlData length], 11 , @"xml data length" );
    [parser setDelegate:catcher];
//	NSLog(@"start testBasicSaxParse");
    [parser parse:xmlData];
//	NSLog(@"catcher messages in testBasicSaxParse: %@",[catcher xxxMesssages]);
    INTEXPECT( [catcher xxxMessageCount],4 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
	EXPECTENDELEMENTAT( catcher,2, @"xml" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:3],@"parserDidEndDocument:" , @"4" );
}

+(void)testBasicSaxParseWithCharacterContent
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"test2"];
//    INTEXPECT( [xmlData length], 11 , @"xml data length" );
    [parser setDelegate:catcher];
//	NSLog(@"start testBasicSaxParse");
    [parser parse:xmlData];
//	NSLog(@"number of messages in testBasicSaxParseWithCharacterContent : %d",[catcher xxxMessageCount]);
//	NSLog(@"catcher messages in testBasicSaxParseWithCharacterContent: %@",[catcher xxxMesssages]);
//    INTEXPECT( [catcher xxxMessageCount],5 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
	EXPECTCHARACTERS( catcher, 2, @"content" );
	EXPECTENDELEMENTAT( catcher,3, @"xml" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"parserDidEndDocument:" , @"4" );
}



+(void)testBasicSaxParseWithElementAndCharacterContent
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"test3"];
//    INTEXPECT( [xmlData length], 11 , @"xml data length" );
    [parser setDelegate:catcher];
//	NSLog(@"start testBasicSaxParse");
    [parser parse:xmlData];
//	NSLog(@"catcher messages in testBasicSaxParseWithElementAndCharacterContent: %@",[catcher xxxMesssages]);
//    INTEXPECT( [catcher xxxMessageCount],10 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
	EXPECTSTARTELEMENTAT( catcher, 2, @"nested1" );
	EXPECTCHARACTERS( catcher, 3, @"content" );
	EXPECTENDELEMENTAT( catcher,4, @"nested1" );
	EXPECTSTARTELEMENTAT( catcher, 5, @"nested2" );
	EXPECTCHARACTERS( catcher, 6, @"content1" );
	EXPECTENDELEMENTAT( catcher,7, @"nested2" );
	EXPECTENDELEMENTAT( catcher,8, @"xml" );
	//--- foundCharacters
    IDEXPECT( [catcher xxxMessageNameAtIndex:9],@"parserDidEndDocument:" , @"9" );
}

+(void)testBasicSaxParseOfEmptyElement
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"emptyelement"];
//    INTEXPECT( [xmlData length], 6 , @"xml data length" );
    [parser setDelegate:catcher];
    
    [parser parse:xmlData];
    INTEXPECT( [catcher xxxMessageCount],4 , @"messages after scan" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
	EXPECTENDELEMENTAT( catcher,2, @"xml" );
    //    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"characterDataAllowed" , @"" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:3],@"parserDidEndDocument:" , @"" );
}

+(void)testEmptyElementWithAttribute
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"emptyElementWithAttribute"];
//    INTEXPECT( [xmlData length], 25 , @"xml data length" );
    [parser setDelegate:catcher];
	
    [parser parse:xmlData];
    INTEXPECT( [catcher xxxMessageCount],4 , @"messages after scan" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"empty" );
	IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:1], @"empty" , @"" );
	EXPECTATTRIBUTEAT( catcher , 1, @"attr", @"someValue");
	EXPECTENDELEMENTAT( catcher,2, @"empty" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:3],@"parserDidEndDocument:" , @"" );
}



+(void)testArchiverSample
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"archiversample"];
//    NSLog(@"will parse: %@",[xmlData stringValue]);
//    INTEXPECT( [xmlData length], 645 , @"xml data length" );
    [parser setDelegate:catcher];

    [parser parse:xmlData];
    INTEXPECT( [catcher xxxMessageCount],16 , @"messages after scan" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"startDocument" , @"" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:1],@"characters:" , @"" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:2],@"startElement:attributes:" , @"" );
    IDEXPECT( [catcher xxxMessageArgumentNumber:0 atIndex:2],@"MPWSubData" , @"first tag" );
//	NSLog(@"after firt tag 3: %@:%@",[catcher xxxMessageNameAtIndex:3],[[catcher xxxMessageArgumentNumber:0 atIndex:3] stringValue]);
//	NSLog(@"after firt tag 4: %@:%@",[catcher xxxMessageNameAtIndex:4],[[catcher xxxMessageArgumentNumber:0 atIndex:4] stringValue]);
    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"startElement:attributes:" , @"" );
    IDEXPECT( [catcher xxxMessageArgumentNumber:0 atIndex:4],@"myData" , @"first tag" );
}

+(void)testAttrParseRunonBug
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *htmlData = [self resourceWithName:@"attrparserunonbug" type:@"html"];
	//    NSLog(@"will parse: %@",[xmlData stringValue]);
	//    INTEXPECT( [xmlData length], 645 , @"xml data length" );
    [parser setDelegate:catcher];
//	NSLog(@"will test attribute run on parse bug\n\n----------\n\n");
    [parser setEnforceTagNesting:NO];
    [parser parse:htmlData];
//	NSLog(@"messages testAttrParseRunonBug: %@",[catcher xxxMesssages] );
//	INTEXPECT( [catcher xxxMessageCount],16 , @"messages after scan" );
 	EXPECTSTARTELEMENTAT( catcher, 1, @"td" );
 	EXPECTSTARTELEMENTAT( catcher, 3, @"a" );
 	EXPECTSTARTELEMENTAT( catcher, 4, @"img" );

	EXPECTATTRIBUTEAT( catcher , 4, @"src", @"g");
	EXPECTATTRIBUTEAT( catcher , 4, @"height", @"220");
	EXPECTATTRIBUTEAT( catcher , 4, @"border", @"0");
/*	
    IDEXPECT( [catcher xxxMessageNameAtIndex:8],@"parser:didEndElement:namespaceURI:qualifiedName:" , @"" );
    IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:8], @"a" , @"" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:10],@"parser:didEndElement:namespaceURI:qualifiedName:" , @"" );
    IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:10], @"td" , @"" );
*/	
}

//	EXPECTATTRIBUTEAT( catcher , 2, @"xmlns", nil);


#define NAMSPACEPREFIXREPORTS( catcher ) \
    IDEXPECT( [catcher xxxMessageNameAtIndex:1],@"parser:didStartMappingPrefix:toURI:" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:1],@"" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:1],@"http://xml.apple.com/cvslog" , @"" );\
    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"parser:didStartMappingPrefix:toURI:" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:1 atIndex:4],@"radar" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:4],@"http://xml.apple.com/radar" , @"" );\


#define NAMESPACETESTS( catcher ) \
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"at start" );\
 	EXPECTSTARTELEMENTAT( catcher, 1, @"cvslog" );\
 	EXPECTSTARTELEMENTAT( catcher, 3, @"radar" );\
	IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:3], @"http://xml.apple.com/radar" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:3 atIndex:3],@"rd:radar" , @"" );\
 	EXPECTSTARTELEMENTAT( catcher, 5, @"bugID" );\
	IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:5], @"http://xml.apple.com/radar" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:3 atIndex:5],@"rd:bugID" , @"" );\
	EXPECTCHARACTERS( catcher, 6, @"2920186" );\
 	EXPECTENDELEMENTAT( catcher, 7, @"bugID" );\
	IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:7], @"http://xml.apple.com/radar" , @"" );\
 	EXPECTSTARTELEMENTAT( catcher, 9, @"title" );\
	IDEXPECT( [catcher xxxMessageArgumentNumber:2 atIndex:9], @"http://xml.apple.com/radar" , @"" );\
    IDEXPECT( [catcher xxxMessageArgumentNumber:3 atIndex:9],@"rd:title" , @"" );\
	EXPECTCHARACTERS( catcher, 10, @"API/NSXMLParser: there ought to be an NSXMLParser" );\
 	EXPECTENDELEMENTAT( catcher, 11, @"title" );\
	INTEXPECT( [catcher xxxMessageCount], 17 ,@"");

	


+(void)testNamespaceParsingNSXML
{
    NSData *xmlData = [self xmlResourceWithName:@"simple-xml-with-namespaces"];
    MPWMessageCatcher* catcher=[[[MPWMessageCatcher alloc] initWithClass:self] autorelease];
	id nsxmlparser = [[[NSXMLParser alloc] initWithData:xmlData] autorelease];
	[nsxmlparser setDelegate:(id)catcher];
	[nsxmlparser setShouldProcessNamespaces:YES];
//	[nsxmlparser setShouldReportNamespacePrefixes:YES];
	[nsxmlparser parse];
//	NSLog(@"NSXMLParser messages: %@",[catcher xxxMesssages]);
	NAMESPACETESTS( catcher )

}


+(void)testNamespaceParsingMPWXML
{
    NSData *xmlData = [self xmlResourceWithName:@"simple-xml-with-namespaces"];
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	[parser setShouldProcessNamespaces:YES];
//	[parser setShouldReportNamespacePrefixes:YES];
	[parser parse:xmlData];
//	NSLog(@"mpwxml messages: %@",[catcher xxxMesssages]);
	NAMESPACETESTS( catcher )

}
+messagesParsingResource:resourceName type:resourceType
{
    NSData *xmlData = [self resourceWithName:resourceName type:resourceType];
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	[parser parse:xmlData];
	return catcher;
}

+(void)testUnquoteAttributesInHtml
{
    MPWMessageCatcher* catcher=[self messagesParsingResource:@"htmlfragment_unquoted_attr_values" type:@"html"];
  	EXPECTSTARTELEMENTAT( catcher, 1, @"td" );
//	NSLog(@"testUnquoteAttributesInHtml:  %@",[catcher messages]);
  	EXPECTATTRIBUTEAT( catcher, 1, @"valign", @"top" );
  	EXPECTATTRIBUTEAT( catcher, 1, @"colspan", @"2" );
}
+(void)testEntitiesInHtml
{
    MPWMessageCatcher* catcher=[self messagesParsingResource:@"htmlfragment_entities" type:@"html"];
  	EXPECTSTARTELEMENTAT( catcher, 1, @"b" );
  	EXPECTCHARACTERS( catcher, 2, @"Apple Applications" );
	EXPECTENTITY( catcher, 3, @"nbsp" );
  	EXPECTCHARACTERS( catcher, 4, @"> and more" );
//  	EXPECTCHARACTERS( catcher, 5, @" and more" );
}

+(void)testAttributeNoValueHtml
{
    MPWMessageCatcher* catcher=[self messagesParsingResource:@"htmlfragment_attribute_no_value" type:@"html"];
//	NSLog(@"mpwxml messages: %@",[catcher xxxMesssages]);
  	EXPECTSTARTELEMENTAT( catcher, 1, @"input" );
//	NSLog(@"attributes messages: %@",ATTRIBUTES( catcher, 1 ));

  	EXPECTCHARACTERS( catcher, 2, @"abc" );
  	EXPECTENDELEMENTAT( catcher, 3, @"input" );
}

+(void)testEntitiesWithNSXMLParser
{
    NSData *xmlData = [self resourceWithName:@"htmlfragment_entities" type:@"html"];
    MPWMessageCatcher* catcher=[[[MPWMessageCatcher alloc] initWithClass:self] autorelease];
	id nsxmlparser = [[[NSXMLParser alloc] initWithData:xmlData] autorelease];
	[nsxmlparser setDelegate:(id)catcher];
	if ( ![nsxmlparser parse] ) {
		NSLog(@"error: %@",[nsxmlparser parserError]);
	}
	NSLog(@"messages: %@",[catcher xxxMesssages]);
  	EXPECTSTARTELEMENTAT( catcher, 1, @"b" );
  	EXPECTCHARACTERS( catcher, 2, @"Apple Applications" );
	EXPECTENTITY( catcher, 3, @"nbsp" );
//	INTEXPECT( [catcher xxxMessageCount],5  , @"no of results");
  	EXPECTCHARACTERS( catcher, 4, @" and more" );
}

+(void)testDashesInXmlComments
{
    NSData *xmlData = [self resourceWithName:@"xml_comment_with_dash" type:@"xml"];
    MPWMessageCatcher* catcher=[[[MPWMessageCatcher alloc] initWithClass:self] autorelease];
	id nsxmlparser = [[[NSXMLParser alloc] initWithData:xmlData] autorelease];
	[nsxmlparser setDelegate:(id)catcher];
	[nsxmlparser parse];
//	NSLog(@"messages: %@",[catcher xxxMesssages]);
  	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
  	EXPECTENDELEMENTAT( catcher, 2, @"xml" );
}

+(void)testAbortDoesntFail
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"test1"];
    [parser setDelegate:catcher];
	[(MPWXmlParserTesting*)catcher setShouldAbort:YES];
    BOOL success=[parser parse:xmlData];
	INTEXPECT( success, YES , @"aborting is not a failure");
}

+(void)testIncrementalParseSplitAt:(int)splitPosition
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"test3"];
	MPWSubData *part1,*part2;
	//    INTEXPECT( [xmlData length], 11 , @"xml data length" );
    [parser setDelegate:catcher];
	//	NSLog(@"start testBasicSaxParse");
	part1=[[[MPWSubData alloc] initWithData:xmlData bytes:[xmlData bytes] length:splitPosition] autorelease];
	part2=[[[MPWSubData alloc] initWithData:xmlData bytes:[xmlData bytes]+splitPosition length:[xmlData length]-splitPosition] autorelease];
//	NSLog(@"part1: '%@'\npart2: '%@'",part1,part2);
	[parser parseSource:[[NSArray arrayWithObjects:part1,part2,nil] objectEnumerator]];

//    [parser parse:xmlData];
	if ( [catcher xxxMessageCount] != 10 ) {
		NSLog(@"catcher messages in testBasicSaxParseWithElementAndCharacterContent: %@",[catcher xxxMesssages]);
	}
	INTEXPECT( [catcher xxxMessageCount],10 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
	EXPECTSTARTELEMENTAT( catcher, 2, @"nested1" );
	EXPECTCHARACTERS( catcher, 3, @"content" );
	EXPECTENDELEMENTAT( catcher,4, @"nested1" );
	EXPECTSTARTELEMENTAT( catcher, 5, @"nested2" );
	EXPECTCHARACTERS( catcher, 6, @"content1" );
	EXPECTENDELEMENTAT( catcher,7, @"nested2" );
	EXPECTENDELEMENTAT( catcher,8, @"xml" );
	//--- foundCharacters
    IDEXPECT( [catcher xxxMessageNameAtIndex:9],@"parserDidEndDocument:" , @"9" );
}

+(void)testIncrementalParseSplitFortuitouslyBetweenCharactersAndTag
{
	[self testIncrementalParseSplitAt:21];
}

+(void)testIncrementalParseSplitInCharacterContent
{
	[self testIncrementalParseSplitAt:19];
}

+(void)testIncrementalParseSplitInTag
{
	[self testIncrementalParseSplitAt:23];
}

+(void)testIncrementalParseSplitInSecondOpenTag
{
	[self testIncrementalParseSplitAt:10];
}




+(void)testBasicDATAParsing
{
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"cdatatest1"];
	[parser setDelegate:catcher];
	//	NSLog(@"start testBasicSaxParse");
	[parser parse:xmlData];
    INTEXPECT( [catcher xxxMessageCount],5 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
  	EXPECTCDATA( catcher, 2, @"Some data with <tags> and stuff" );
	EXPECTENDELEMENTAT( catcher,3, @"xml" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"parserDidEndDocument:" , @"4" );
}

+(void)testIncrementalDATAParsing
{
	int splitPosition=20;
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
    NSData *xmlData = [self xmlResourceWithName:@"cdatatest1"];
	[parser setDelegate:catcher];
	//	NSLog(@"start testBasicSaxParse");
	id part1=[[[MPWSubData alloc] initWithData:xmlData bytes:[xmlData bytes] length:splitPosition] autorelease];
	id part2=[[[MPWSubData alloc] initWithData:xmlData bytes:[xmlData bytes]+splitPosition length:[xmlData length]-splitPosition] autorelease];
//	NSLog(@"CDATA part1: '%@'\npart2: '%@'",part1,part2);
	[parser parseSource:[[NSArray arrayWithObjects:part1,part2,nil] objectEnumerator]];
	if ( [catcher xxxMessageCount] != 5 ) {
		NSLog(@"catcher messages in testIncrementalDATAParsing: %@",[catcher xxxMesssages]);
	}
	
    INTEXPECT( [catcher xxxMessageCount],5 , @"messages after scan" );   
    IDEXPECT( [catcher xxxMessageNameAtIndex:0],@"parserDidStartDocument:" , @"0" );
	EXPECTSTARTELEMENTAT( catcher, 1, @"xml" );
  	EXPECTCDATA( catcher, 2, @"Some data with <tags> and stuff" );
	EXPECTENDELEMENTAT( catcher,3, @"xml" );
    IDEXPECT( [catcher xxxMessageNameAtIndex:4],@"parserDidEndDocument:" , @"4" );
}

#if !WINDOWS && !LINUX
+(void)testUTF8XmlMojibake
{
	NSData  *mojibake_source=[self frameworkResource:@"mojibake_utf8" category:@"xhtml"];
    MPWMessageCatcher* catcher=[self catcher];
	NSString	*expectedResult=[NSString stringWithContentsOfFile:[self frameworkPath:@"mojibake_utf16.txt"] encoding:NSUTF16StringEncoding error:nil];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	EXPECTNOTNIL( mojibake_source, @"should have source" );
	[parser parse:mojibake_source];
	IDEXPECT( [(MPWXmlParserTesting*) catcher totalText], expectedResult, @"Mojibake");
}
#endif
+(void)testUTF8XHTMLTest
{
	NSData  *xhtml_source=[self frameworkResource:@"utf8xhtml_test" category:@"html"];
    MPWMessageCatcher* catcher=[self catcher];
	NSString	*expectedResult=[NSString stringWithContentsOfFile:[self frameworkPath:@"utf8xhtml_test.txt"] encoding:NSUTF8StringEncoding error:nil];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	EXPECTNOTNIL( xhtml_source, @"should have source" );
	EXPECTNOTNIL( expectedResult, @"should have expected result" );
	[parser parse:xhtml_source];
	IDEXPECT( [(MPWXmlParserTesting*) catcher totalText], expectedResult, @"utf8xhtml");
}

+(void)testNakedAmpersand
{
	NSData  *xhtml_source=[self frameworkResource:@"Dg-duplex" category:@"htm"];
    MPWMessageCatcher* catcher=[self catcher];
	NSString	*expectedResult=@"Duplex Printing & Margin";
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	[parser setEnforceTagNesting:NO];
	EXPECTNOTNIL( xhtml_source, @"should have source" );
	[parser parse:xhtml_source];
	IDEXPECT( [(MPWXmlParserTesting*) catcher totalText], expectedResult, @"utf8xhtml");
	
}

+(void)testSAXParserHandlesMetaTagEncodingForHTML
{
	NSData  *xhtml_source=[self frameworkResource:@"c1qt12" category:@"html"];
	NSString *expectedResult =[[[[NSString alloc] initWithData:[self frameworkResource:@"c1qt12" category:@"txt"] encoding:NSUTF8StringEncoding] autorelease] substringFromIndex:1];
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	[parser setEnforceTagNesting:NO];
	[parser setIgnoreCase:YES];
	EXPECTNOTNIL( xhtml_source, @"should have source" );
	[parser parse:xhtml_source];
	//	NSLog(@"parser dataEncoding: %d",[parser dataEncoding]);
	//	NSLog(@"result: '%@'",[(MPWXmlParserTesting*)catcher totalText]);
	IDEXPECT( [(MPWXmlParserTesting*) catcher totalText], expectedResult, @"utf8xhtml");
}

+(void)testSAXParserHandlesMetaTagEncodingForHTMLEvenIfISOAndUTF8Clash
{
	NSData  *xhtml_source=[self frameworkResource:@"accent_grave" category:@"html"];
	NSString *expectedResult =[[[NSString alloc] initWithData:[self frameworkResource:@"accent_grave" category:@"txt"] encoding:NSUTF8StringEncoding] autorelease];
    MPWMessageCatcher* catcher=[self catcher];
    MPWSAXParser* parser = [self parser];
	[parser setDelegate:catcher];
	[parser setEnforceTagNesting:NO];
	[parser setIgnoreCase:YES];
	EXPECTNOTNIL( xhtml_source, @"should have source" );
	[parser parse:xhtml_source];
	//	NSLog(@"parser dataEncoding: %d",[parser dataEncoding]);
	//	NSLog(@"result: '%@'",[(MPWXmlParserTesting*)catcher totalText]);
	IDEXPECT( [(MPWXmlParserTesting*) catcher totalText], expectedResult, @"utf8xhtml");
}

+(void)testNSXMLParserErrorForTagMismatch
{
	NSData *testData=[@"<xml><h>content</xml>" dataUsingEncoding:NSASCIIStringEncoding];
	NSXMLParser *ns_parser=[[[NSXMLParser alloc] initWithData:testData] autorelease];
	MPWSAXParser *parser=[[[MPWSAXParser alloc] initWithData:testData] autorelease];
	EXPECTFALSE( [ns_parser parse], @"parsing should fail");
	EXPECTNOTNIL( [ns_parser parserError], @"parse error");

	INTEXPECT( [[ns_parser parserError] code],111, @"error code");

	EXPECTFALSE( [parser parse], @"parsing should fail");
	EXPECTNOTNIL( [parser parserError], @"parse error");

	INTEXPECT( [[parser parserError] code],76, @"error code");
}

+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:
        @"testBasicSaxParse",
		@"testBasicSaxParseWithCharacterContent",
		@"testBasicSaxParseWithElementAndCharacterContent",
        @"testBasicSaxParseOfEmptyElement",
        @"testEmptyElementWithAttribute",
        @"testAttrParseRunonBug",
        @"testNamespaceParsingMPWXML",
		@"testUnquoteAttributesInHtml",
		@"testEntitiesInHtml",
#if !WINDOWS			
		@"testNamespaceParsingNSXML",
//		@"testEntitiesWithNSXMLParser",
		@"testNSXMLParserErrorForTagMismatch",
		@"testDashesInXmlComments",
#endif
		@"testAttributeNoValueHtml",
		@"testAbortDoesntFail",
		@"testIncrementalParseSplitFortuitouslyBetweenCharactersAndTag",
			@"testIncrementalParseSplitInTag",
			@"testIncrementalParseSplitInSecondOpenTag",
			@"testIncrementalParseSplitInCharacterContent",
			@"testBasicDATAParsing",
			@"testIncrementalDATAParsing",
			@"testUTF8XmlMojibake",
			@"testUTF8XHTMLTest",
			@"testNakedAmpersand",
			@"testSAXParserHandlesMetaTagEncodingForHTML",
			@"testSAXParserHandlesMetaTagEncodingForHTMLEvenIfISOAndUTF8Clash",
//        @"testArchiverSample",
        nil];
}

@end

