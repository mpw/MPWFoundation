/* SaxDocumentHandler.h Copyright (c) 1999-2006 by Marcel P. Weiher.  All Rights Reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

        Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

        Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the distribution.

        Neither the name Marcel Weiher nor the names of contributors may
        be used to endorse or promote products derived from this software
        without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.


*/

@protocol SaxDocumentHandler

-(void)parserDidStartDocument:(NSXMLParser *)parser;
-(void)parserDidEndDocument:(NSXMLParser *)parser;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
-(void)parser:(NSXMLParser *)aParser didStartMappingPrefix:aPrefix toURI: uri;
-(void)parser:(NSXMLParser *)aParser didEndMappingPrefix:aPrefix;
-(NSData *)parser:(NSXMLParser *)aParser resolveExternalEntityName:(NSString *)name systemID:(NSString *)systemId;
-(void)parser:(NSXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;

//-(void)processingInstructionTarget:piTarget data:piData;
//-(void)cdata:cdata;
//-(void)ignorableWhiteSpace:data;


@end

@protocol AppKitSaxDocumentHandler



@end


@protocol MPWXmlScannerDelegate
@optional

-(BOOL)beginElement:(const char*)fullyQualifedPtr length:(long)len nameLen:(long)fullyQualifiedLen namespaceLen:(long)namespaceLen;
-(BOOL)endElement:(const char*)fullyQualifedPtr length:(long)fullyQualifiedLen namespaceLen:(long)namespaceLen;
-(BOOL)makeText:(const char*)start length:(long)len firstEntityOffset:(long)entityOffset;
-(BOOL)makeSpace:(const char*)start length:(long)len;
-(BOOL)makeCData:(const char*)start length:(long)len;
-(BOOL)makeSgml:(const char*)start length:(long)len nameLen:(long)nameEnd;
-(BOOL)makePI:(const char*)start length:(long)len nameLen:(long)nameLen;
-(BOOL)attributeName:(const char*)nameStart length:(long)nameLen value:(const char*)valueStart length:(long)valueLen namespaceLen:(long)namespaceLen valueHasHighBit:(BOOL)highBit;
-(BOOL)makeEntityRef:(const char*)start length:(long)len;

@end
