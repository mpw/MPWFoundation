/* MPWXmlGeneratorStream.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Mon 26-Oct-1998 */

#import <Foundation/Foundation.h>
#import <MPWFlattenStream.h>


@interface MPWXmlGeneratorStream : MPWFlattenStream 
{
    BOOL		atBOL;
    int         indent;
	BOOL		shouldIndent;
	const char	*tagStack[1024];
	int			curTagDepth;
    id          byteTarget;
}

typedef void (^XmlGeneratorBlock)(MPWXmlGeneratorStream* );


-writeStartTag:(const char*)name attributes:attrs single:(BOOL)isSingle;
-startTag:(const char*)tag;
-writeCloseTag:(const char*)name;
-closeTag;
-(void)writeAttribute:(NSString*)attributeName value:(NSString*)attributeValue;
-(void)writeCStrAttribute:(const char*)attributeName cStrValue:(const char*)attributeValue;
-(void)writeCStrAttribute:(const char*)attributeName intValue:(long)intValue;
-(void)writeCStrAttribute:(const char*)attributeName doubleValue:(double)doubleValue;

-(void)beginStartTag:(const char*)name;
-(void)endStartTag:(const char*)name single:(BOOL)isSingle;

-writeElementName:(const char*)name attributes:attrs contents:contents;
-writeElementName:(const char*)name contents:contents;
-writeContentObject:anObject;
-(void)writeProcessingInstruction:piName attributes:attrs;
-(void)writeStandardXmlHeader;
-(void)writeString:aString;
-(void)writeCData:(NSData*)data;
-(void)indent;
-(void)outdent;
-(void)cr;
-(void)writeNSDataContent:(NSData*)data;
-(void)writeCStrAttribute:(const char*)attributeName value:(NSString*)attributeValue;

-(void)writeContent:anObject;
-(void)setShouldIndent:(BOOL)should;
-(BOOL)shouldIndent;
-(id)writeElementName:(const char *)name attributeBlock:(XmlGeneratorBlock)attrs contentBlock:(XmlGeneratorBlock)content;

@end

@interface NSObject(MPWXmlGeneratorStream)

-(void)generateXmlContentOnto:(MPWXmlGeneratorStream*)aStream;
-(void)generateXmlOnto:(MPWXmlGeneratorStream*)aStream;
-(BOOL)isSimpleXmlContent;
@end

#import <MPWByteStream.h>

@interface MPWXMLByteStream : MPWByteStream
{
}


@end

