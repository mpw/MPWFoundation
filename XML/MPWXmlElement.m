/* MPWXmlElement.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

#import "MPWXmlElement.h"
#import "MPWXmlGeneratorStream.h"

@interface MPWXmlElement(private)

-(void)setParent:newParent;
-(NSArray*)subelements;
@end

@implementation MPWXmlElement

idAccessor( name, setName )
idAccessor( attributes, setAttributes)
idAccessor( subelements, setSubelements)
scalarAccessor( id, parent, setParent )
idAccessor( elementBytes, setElementBytes )
boolAccessor( isIncomplete, setIsIncomplete )


- retain
{
    return retainMPWObject( (MPWObject*)self );
}

- (NSUInteger)retainCount
{
    return _retainCount+1;
}

- (oneway void)release
{
    releaseMPWObject((MPWObject*)self);
}


-(void)markDirty
{
//	NSLog(@"markDirty: %@",self);
	if (!isDirty ) {
		isDirty=YES;
		[parent markDirty];
	}
}

-childAtIndex:(NSUInteger)offset
{
    return [subelements objectAtIndex:offset];
}

-children
{
	return subelements;
}

-(void)insertElement:anElement before:otherElement
{
    NSInteger otherIndex;
    if ( !subelements ) {
        [self setSubelements:[NSMutableArray array]];
    }
//    NSLog(@"insert element: %@ (%d, %@)",anElement,[anElement length],[anElement class]);
  [anElement setParent:self];
    if ( otherElement!=nil &&
         (otherIndex=[subelements indexOfObject:otherElement])!=NSNotFound) {
        [subelements insertObject:anElement atIndex:otherIndex];
    } else {
        [subelements addObject:anElement];
    }
}

-(void)addElement:anElement
{
    if ( !subelements ) {
        [self setSubelements:[NSMutableArray array]];
    }
    [subelements addObject:anElement];
	[anElement setParent:self];
}

-(void)removeElement:anElement
{
    [subelements removeObject:anElement];
}

-(NSEnumerator*)elementEnumerator
{
    return [subelements objectEnumerator];
}

-(NSUInteger)count
{
    return [subelements count];
}

-(BOOL)hasChildren
{
    return subelements && [self count];
}

-initWithName:aName attributes:attrs subelements:elements
{
    self = [super init];
    [self setName:aName];
    [self setAttributes:attrs];
    [self setSubelements:elements];
	isDirty=NO;
    return self;
}

-initWithName:aName
{
    return [self initWithName:name attributes:nil subelements:nil];
}

-(void)dealloc
{
    [attributes release];
    [subelements release];
	[name release];
	[elementBytes release];
    [super dealloc];
}

-(void)writeObject:anObject
{
    [self addElement:anObject];
}

-(BOOL)isEqual:other
{
    return self == other ||
    ([[self name] isEqual:[(MPWXmlElement*)other name]] &&
     [[self attributes] isEqual:[other attributes]] &&
     [[self subelements] isEqual:[other subelements]]);
}

-description
{
    return [NSString stringWithFormat:@"%@: name=%@, attributes=%@, subelements=%@/%@",
        [self class],[self name],[self attributes],[subelements class],subelements];
}

-attributeForKey:aKey
{
    return [attributes objectForKey:aKey];
}

-(void)generateXmlContentOnto:(MPWXmlGeneratorStream*)aStream
{
	if ( !isDirty && elementBytes ) {
		[aStream writeObject:elementBytes];
	} else {
		[super generateXmlContentOnto:aStream];
	}
}
-(void)generateXmlOnto:(MPWXmlGeneratorStream*)aStream
{
	if ( !isDirty && elementBytes ) {
		[aStream writeObject:elementBytes];
	} else {
		[super generateXmlOnto:aStream];
	}
}

@end


