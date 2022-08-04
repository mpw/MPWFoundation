/* MPWXmlScanner.m Copyright (c) Marcel P. Weiher 1998-2008, All Rights Reserved,
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

, created  on Sun 23-Aug-1998 */

#import "MPWXmlScanner.h"
//#import "MPWXmlScanner16BitBE.h"
#import "SaxDocumentHandler.h"
#import <AccessorMacros.h>
#import <objc/message.h>
#if 0

@interface NSData(swapBytes)

-(NSData*)swappedUnichars;
-(NSData*)initWithSwappedShortsOf:(short*)shorts length:(unsigned)shortLen;

@end
@implementation NSData(swapBytes)

-(NSData*)initWithSwappedShortsOf:(short*)shorts length:(unsigned)shortLen
{
    short *swapped=malloc(  sizeof *swapped * shortLen );
    int i;
    for (i=0;i<shortLen;i++) {
        swapped[i]=NSSwapShort( shorts[i] );
    }
    return [self initWithBytesNoCopy:(void*)swapped length:shortLen*2];
}

-(NSData*)swappedUnichars
{
    return [[[NSData alloc] initWithSwappedShortsOf:(short*)[self bytes] length:[self length]/2] autorelease];
}

@end

@implementation MPWSubData(swapBytes)

-(NSData*)swappedUnichars
{
    return [[[NSData alloc] initWithSwappedShortsOf:(short*)[self bytes] length:[self length]/2] autorelease];
}


@end
#endif 
@implementation NSXMLScanner
/*"
     An MPWXmlScanner segments 8 or 16 bit character data according to the XML specification.
     It provides pointers
     into the original data via call-backs and does not perform any further processing.  The intent
     is for MPWXmlScanner to serve as the lowest level of XML input-processing with minimal
     overhead and the ability to re-create the input file with 100% fidelity.  Any types of
     conversions, processing or policy decisions are left for higher levels to take care of.

     It can handle 8 bit ISO/ASCII and 16 bit Unicode encoded files.  UTF-8 files aren't treated
     specially but can be handled as-is due to the nature of the UTF-8 encoding (all XML-relevant
     syntactical entities have the same code positions as in ASCII).  Conversion of actual encoded
     content is left to clients/subclasses of MPWXmlScanner.  Sixteen bit data with non-native endianness
     is byte-swapped wholesale before reading as a stopgap measure.
     
"*/


scalarAccessor( id, delegate, _setDelegate )

#define IMPSEL( theSel )   [delegate methodForSelector:@selector(theSel) ]

-(void)_initDelegation
{
	if ( nil != delegate ) {
         text            = IMPSEL(makeText:length:firstEntityOffset:);
         space           = IMPSEL(makeSpace:length:);
         cdataTagCallback = IMPSEL(makeCData:length:);
         sgml            = IMPSEL(makeSgml:length:nameLen:);
         pi                      = IMPSEL(makePI:length:nameLen:);
         openTag         = IMPSEL(beginElement:length:nameLen:namespaceLen:);
         closeTag        = IMPSEL(endElement:length:namespaceLen:);
         attVal          = IMPSEL(attributeName:length:value:length:namespaceLen:valueHasHighBit:);
         entityRef       = IMPSEL(makeEntityRef:length:);
	}
}

-(void)setDelegate:aDelegate
{
	[self _setDelegate:aDelegate];
	[self _initDelegation];
}

+parser
{
	return [[[self alloc] init] autorelease];
}

+stream { return [self parser]; }

typedef char xmlchar;

#if 1
/* XmlScannerPseudoMacro.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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
 
 , created  on Tue 22-Jun-1999 */


//---	needs to be defined 

#define SCAN_OK 0
#define SCAN_UNCLOSED_TAG 1
#define SCAN_OTHER_ERROR 9

typedef enum {
    inText = 0,inSpace,
    inTag,inCloseTag,
    inDeclaration,inProcessingInstruction,
    //    inEntityRef,
    inComment,inCData,
    scanDone, inAttributeName,inAttributeValue} scanStateType;

#import "XmlCommonMacros.h"

#define CHARSLEFT(n)   (endPtr-currentPtr > n)
#define	INRANGE	( CHARSLEFT(0) )
#define  CURRENTCHARCOUNT  (currentPtr - currentString)
#define  CURRENTBYTECOUNT  ((char*)currentPtr - (char*)currentString)

#define  SECURECALLBACK( callback )  if ( callback == NULL ) { callback = (void*)processDummy;  }
#define  XMLKITCALLBACK( whichCallBack )  whichCallBack( clientData, NULL, currentString, CURRENTCHARCOUNT,spaceOffset ,namespaceLen )


typedef BOOL (*ProcessFunc) (void *target, void* dummySel,const xmlchar *, unsigned long length,unsigned long nameLen,long namespaceLen);
typedef BOOL (*AttrFunc) (void *target, void* dummySel,const xmlchar *, unsigned long ,const xmlchar *,unsigned long, long namespaceLen, BOOL valueHasHighBit);


static BOOL processDummy( void *dummyTarget ,void *dummySel ,const xmlchar *textPtr, unsigned int charCount,unsigned int nameLen)
{
    //    NSLog(@"dummy processor");
    
    
    return YES;
}

#ifndef	CDATATAG
#define	CDATATAG	"<![CDATA["
#endif
#define	CDATALENGTH	9


#ifndef	ENDCOMMENT
#define ENDCOMMENT	"-->"
#endif
#define ENDCOMMENTLENGTH 3

#ifndef	CHARCOMP
#define	CHARCOMP	strncmp
#endif


static inline scanStateType checkForMarkup( const xmlchar *start, const xmlchar *end )
{
    xmlchar ch=NATIVECHAR(*start);
    if ( ch == XMLCHAR( '<' )) {
        ch = NATIVECHAR(start[1]);
        if ( isalnum( ch ) ) {
            return inTag;
        } else if ( ch=='/' ) {
            return inCloseTag;
        } else if ( ch=='!' ) {
            if ( end-start > 2 ) {
                if ( ISHYPHEN(start[2]) && ISHYPHEN(start[3])) {
                    return inComment;
                } else if ( end-start > CDATALENGTH &&
                           !CHARCOMP( start,CDATATAG,CDATALENGTH )) {
                    return inCData;
                }
            }
            return inDeclaration;
        } else if ( ch == '?' ) {
            return inProcessingInstruction;
        }
    }
    return isspace(ch) ? inSpace : inText;
}

/**
 * tries to skip a comment.
 */
//static inline const xmlchar *
//tryToSkipComment( const xmlchar *start, const xmlchar *end )
//{
//    const xmlchar *currentPtr = start;
//    if (end-start == 0 || !ISHYPHEN(start[0])  ||  !ISHYPHEN(start[1]))  {
//        return currentPtr+1;
//    } else {
//        currentPtr += 2;;
//    }
//    while ( (currentPtr+1) < end && !ISHYPHEN(currentPtr[0]) && !ISHYPHEN(currentPtr[1]))  {
//        currentPtr++;
//    }
//    if ((currentPtr+1) < end) {
//        currentPtr +=2;
//    }
//    return currentPtr;
//}


static int scanXml(
                   const xmlchar *data,
                   unsigned long charCount,
                   ProcessFunc openTagCallback,
                   ProcessFunc closeTagCallback,
                   ProcessFunc declarationCallback,
                   ProcessFunc processingInstructionCallback,
                   ProcessFunc entityReferenceCallback,
                   ProcessFunc textCallback,
                   ProcessFunc spaceCallback,
                   ProcessFunc cdataCallback,
                   AttrFunc attributeValueCallBack,
                   void *clientData)
{
    const xmlchar *endPtr;
    const xmlchar *currentPtr;
    scanStateType scanState = inText;
    SECURECALLBACK( openTagCallback );
    SECURECALLBACK( closeTagCallback );
    SECURECALLBACK( declarationCallback );
    SECURECALLBACK( processingInstructionCallback );
    SECURECALLBACK( entityReferenceCallback );
    SECURECALLBACK( textCallback );
    SECURECALLBACK( spaceCallback );
    SECURECALLBACK( cdataCallback );
	SECURECALLBACK( attributeValueCallBack );
    currentPtr=data;
    endPtr=data + charCount;
    //	NSLog(@"start scan with %c",*currentPtr);
    //	NSLog(@"start scan with client data %x",clientData);
    while ( currentPtr < endPtr ) {
        const xmlchar *currentString = currentPtr;
        long spaceOffset=0;
        long namespaceLen=0;
        ProcessFunc currentCallback;
        
		//--- scan up to the beginning of a tag (the initial '<' )
		
		//--- first scan up to any occurence of an ampersand
		
		while ( INRANGE && isspace( *currentPtr ) ) {
			currentPtr++;
		}
		spaceOffset=CURRENTCHARCOUNT;
        namespaceLen=0;
        while ( INRANGE && !ISOPENTAG(*currentPtr)  ) {
			//			NSLog(@"char '%c' isopentag: %d",*currentPtr,ISOPENTAG(*currentPtr));
			if ( CHARSLEFT(2) && ISAMPERSAND( *currentPtr) && !isspace(currentPtr[1]) ) {
				break;
			}
			currentPtr++;
		}
		//--- report any characters that occured before the initial '<'
        
        if ( CURRENTCHARCOUNT > 0 ) {
            //					NSLog(@"do top textCallback");
            if ( spaceOffset == CURRENTCHARCOUNT ) {
                //						NSLog(@"spaceCallback");
                XMLKITCALLBACK( spaceCallback );
            } else {
                XMLKITCALLBACK( textCallback );
            }
        }
        if (!INRANGE) {
            break;
        }
        if ( CHARSLEFT(2) && ISAMPERSAND( *currentPtr )) {
            currentString=currentPtr;
            currentPtr+=2;		//	have at least 1 character after the & so I can skip over that as well
            while ( INRANGE && !ISSEMICOLON( *currentPtr ) && !isspace( *currentPtr ) ) {
                currentPtr++;
            }
            if ( INRANGE && ISSEMICOLON( *currentPtr  )) {
                currentPtr++;
            }
            XMLKITCALLBACK( entityReferenceCallback );
            
            //----	start back at the top, whereas usually we try to take advantage of the tag/chars 
            //----	rythm to just go straight to tag processing
            
            continue;
        }
        
		//---	now begin processing a (potential) tag
        
        currentString = currentPtr;
        
		//---	skip over the initial '<' 
		if ( INRANGE ) {
            currentPtr++;
            scanState = inTag;
		} else {
			break;
		}
        //---	we initially think it's an open tag, might revise this later
		
        currentCallback=openTagCallback;
        
        if (INRANGE && isalnum(*currentPtr)) {
            //--- it's an open tag (or an empty tag)
        } else {
            //--- it's something else, check the possibilities
            if ( INRANGE && *currentPtr == '/' ) {
                currentCallback=closeTagCallback;
                currentPtr++;
            } else if ( INRANGE && *currentPtr == '!' ) {
                currentPtr++;
                if ( *currentPtr=='[' && ( CHARSLEFT(CDATALENGTH) &&
                                          !CHARCOMP( currentPtr,&CDATATAG[2],CDATALENGTH-2 ))) {
                    currentPtr+=CDATALENGTH;
                    scanState = inCData;
                    //---	searching for CDataEnd "]]>" via hard-coded Boyer-Moore variant
                    while ( INRANGE /* termination via break in '>' case */ ) {	
                        if ( ISCLOSETAG(*currentPtr) ) {
                            if ( ISRIGHTSQUAREBRACKET(currentPtr[-1]) && ISRIGHTSQUAREBRACKET(currentPtr[-2])) {
                                //                                        NSLog(@"end of CDATA section");
                                currentPtr++;
                                break;
                            } else {
                                currentPtr+=3;
                            }
                        } else if ( ISRIGHTSQUAREBRACKET(currentPtr[0]) ) {
                            currentPtr+=1;
                        } else {
                            currentPtr+=3;
                        }
                    }
                    if ( INRANGE ){ 
                        XMLKITCALLBACK( cdataCallback );
                        continue;
                    } else {
                        break;
                    }
                } else if ( *currentPtr=='-' && currentPtr[1]=='-' ) {
//                    currentCallback=declarationCallback;
                    currentPtr+=2;
                    scanState = inComment;
                    do {
                        while ( INRANGE && !ISHYPHEN(*currentPtr) ) {
                            currentPtr++;
                        }
                        if (  CHARSLEFT(ENDCOMMENTLENGTH) && !CHARCOMP( currentPtr, ENDCOMMENT,ENDCOMMENTLENGTH)) {
                            currentPtr+=ENDCOMMENTLENGTH;
                            XMLKITCALLBACK( declarationCallback );
                            scanState = checkForMarkup( currentPtr, endPtr );
                        } else if ( INRANGE ) {
                            currentPtr++;
                        }
                    } while ( CHARSLEFT(ENDCOMMENTLENGTH) && scanState == inComment );
                    continue;
                } else {
                    currentCallback=declarationCallback;
                    while ( INRANGE && !ISCLOSETAG(*currentPtr) ) {
                        currentPtr++;
                    }
                }
            } else if ( INRANGE && *currentPtr == '?' ) {
                currentCallback=processingInstructionCallback;
                currentPtr++;
            }
        }
        
        // --- scan over name of tag
        
        //			  NSLog(@"scan over name or tag: %c",*currentPtr);
        while ( INRANGE && !isspace(*currentPtr) && !ISCLOSETAG(*currentPtr) && !ISNAMESPACEDELIMITER(*currentPtr) ) {
            currentPtr++;
        }
        if ( INRANGE && ISNAMESPACEDELIMITER(*currentPtr)) {
            namespaceLen=CURRENTCHARCOUNT;
        }
        while ( INRANGE && !isspace(*currentPtr) && !ISCLOSETAG(*currentPtr) ) {
            currentPtr++;
        }
        if ( currentCallback==closeTagCallback ) {
            spaceOffset=namespaceLen;
        } else {
            spaceOffset=CURRENTCHARCOUNT;
        }
        //			  NSLog(@"did scan over name or tag: %c, charCount: %d",*currentPtr,CURRENTCHARCOUNT);
        //			  NSLog(@"scan attributes");
        
        // --- scan attributes
        
        
        while ( INRANGE && ( *currentPtr != '/' && *currentPtr != '>' )  ) {
            const xmlchar *attNameStart;
            const xmlchar *attNameEnd;
            xmlchar attValDelim=' ';
            const xmlchar *attValStart,*attValEnd;
            scanStateType saveState = scanState;
            long attrNameSpaceLen=0;
            //--- scan over any leading whitesspace
            
            while ( INRANGE &&  isspace(*currentPtr)) {
                currentPtr++;
            }
            
            //--- scan over name of attribute
            
            attNameStart=currentPtr;
            scanState=inAttributeName;
            while ( INRANGE && *currentPtr != '=' && !ISCLOSETAG(*currentPtr) && !ISNAMESPACEDELIMITER(*currentPtr)) {
                currentPtr++;
            }
            if ( INRANGE && ISNAMESPACEDELIMITER(*currentPtr)) {
                attrNameSpaceLen=currentPtr-attNameStart;
                currentPtr++;
            }
            while ( INRANGE && *currentPtr != '=' && !ISCLOSETAG(*currentPtr)) {
                currentPtr++;
            }
            if ( currentPtr == attNameStart ) {
                break;
            }
            attNameEnd = currentPtr;
            
            //--- remove any trailing space between the attribute name and the '='
            
            while ( attNameEnd > attNameStart &&  isspace(attNameEnd[-1])) {
                attNameEnd--;
            }
            
            //---	scan over the '='
            xmlchar valueMask=0;
            if ( INRANGE && !ISCLOSETAG( *currentPtr ) ) {
                
                currentPtr++;
                
                //--- remove any leading space between the '=' and the attribute value
                
                while ( INRANGE &&  isspace(*currentPtr)) {
                    currentPtr++;
                }
                
                //---	scan the attribute value
                
                if (INRANGE && (*currentPtr == '"' || *currentPtr=='\'') ) {
                    attValDelim=*currentPtr;
                    currentPtr++;
                }
                
                attValStart=currentPtr;
//                scanState=inAttributeValue;
                while ( INRANGE && *currentPtr != attValDelim && !ISCLOSETAG(*currentPtr)) {
                    valueMask |= *currentPtr;
                    currentPtr++;
                }
                attValEnd=currentPtr;
                
                //--- skip over duplicated close quotes (some HTML files have this)
                
                if ( INRANGE && *currentPtr == attValDelim ) {
                    currentPtr++;
                }
            } else {
                //--- found close tag after just the attribute name (key)  -> this is probably an error!
                attValStart=attNameEnd;
                attValEnd=attValStart;
            }
            BOOL valueHasHighBit= (valueMask & 0x80)==0x80;
            if ( INRANGE ) {
                attributeValueCallBack( clientData, NULL, attNameStart, attNameEnd-attNameStart, attValStart, attValEnd-attValStart,attrNameSpaceLen, valueHasHighBit );
            }
            if ( INRANGE && attValDelim!=' ' && *currentPtr == attValDelim ) {
                currentPtr++;
            }
            scanState=saveState;
        }
        while ( INRANGE && (isspace(*currentPtr) ||ISSLASH(*currentPtr)) ) {
            currentPtr++;
        }
        if (  INRANGE && *currentPtr=='?' ) {
            currentPtr++;
            currentCallback = processingInstructionCallback;
        } 
        //--- finished parsing tag, should now have a '>' 
        if ( INRANGE && ISCLOSETAG(*currentPtr) ) {
            //--- skip over the '>'
            currentPtr++;
            XMLKITCALLBACK( currentCallback );
            scanState=inText;
        } else if ( INRANGE ) {
            //--- did not encounter closing '>', confused, just do a text callback
            //--- maybe I should signal an error here?
            //					NSLog(@"textCallBack");
            XMLKITCALLBACK( textCallback );
        }
    }
    switch (scanState) {
        case inTag:
        case inDeclaration:
        case inAttributeName:
        case inAttributeValue:
		case inCData:
            //			NSLog(@"scan state: %d",scanState);
            return SCAN_UNCLOSED_TAG;
        default:
            return SCAN_OK;
    }
}                


#else

#include "XmlScannerPseudoMacro.h"
#endif

idAccessor( data, setData )

 -(BOOL)scan8bit:(NSData*)aData
{
//    ProcessFunc entityRef = (ProcessFunc)[self methodForSelector:@selector(makeEntityRef:length:)];
	BOOL success=NO;
	id oldData=[[self data] retain];
	[self setData:aData];
    
    success=(scanXml( [data bytes], [data length] / sizeof(xmlchar),  openTag, closeTag, sgml,pi,entityRef, text,space,cdataTagCallback,attVal, delegate )==SCAN_OK);
	[self setData:oldData];
    [oldData release];
	return success;
}


-convert16BitUnicodeToUTF8:utf16data
{
	id string=[[NSString alloc] initWithData:utf16data encoding:NSUnicodeStringEncoding];
	id utf8data=[string dataUsingEncoding:NSUTF8StringEncoding];
	[string release];
	return utf8data;
}


-(BOOL)parse:(NSData*)aData
/*"
    Scan the data object, which can contain 8 bit ASCII compatible or 16 bit Unicode characters.
    Perform the call-backs described above for various XML syntactic structures found in the
    character data.  Does not perform validity or even well-formedness checking.
 
    Sixteen bit data is recognized by the header word 0xfffe, for data with non-native endianness,
    a byte-swapped copy is scanned.
"*/
{
    if ( [aData length] >= 2 ) {
        const unsigned short *chars=(unsigned short*)[aData bytes];
        if ( *chars == 0xfffe ||  *chars == 0xfeff  ) {
//			NSLog(@"convert 16 bit to 8 bit!");
			aData=[self convert16BitUnicodeToUTF8:aData];
		}
    }
    return [self scan8bit:aData];
}


-(void)dealloc
{
    [data release];
//	[delegate release];
    [super dealloc];
}

@end
