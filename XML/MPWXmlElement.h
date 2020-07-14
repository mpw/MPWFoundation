/* MPWXmlElement.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Mon 28-Sep-1998 */

#import <Foundation/Foundation.h>
#import <AccessorMacros.h>

@interface MPWXmlElement : NSObject
{
	NSInteger _retainCount;
    id	name;
    id	attributes; 
    id	subelements;
    id	parent;
	id	elementBytes;
	BOOL	isIncomplete,isDirty;
}

idAccessor_h( name, setName )
idAccessor_h( attributes, setAttributes)
idAccessor_h( subelements, setSubelements)
idAccessor_h( parent, setParent )
idAccessor_h( elementBytes, setElementBytes )
boolAccessor_h( isIncomplete, setIsIncomplete )

-initWithName:name attributes:attrs subelements:elements;
-attributeForKey:akey;
-childAtIndex:(NSUInteger)offset;
-(NSEnumerator*)elementEnumerator;
-(NSUInteger)count;

//---	mutable

//-(void)insertElement:anElement before:otherElement;
-(void)addElement:anElement;
//-(void)removeElement:anElement;
-(BOOL)hasChildren;

//-objectForXPointer:xPointer;

@end


//---	issues: DOM has explicit parent and document pointers
//---			this allows access to siblings etc.
//---			however it mandates containment

