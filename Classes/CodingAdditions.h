/* CodingAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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


#import <Foundation/Foundation.h>

//#define encodeObject( coder, name )  [(coder) encodeObject:name withName:@"##name##"]
//#define decodeObject( coder, name )  name=[[(coder) decodeObjectWithName:@"##name##"] retain]

//#define  QUICKSTRING( str )	(MPWUniqueString( (str), (sizeof (str))-1))
#define  QUICKSTRING( str )	( @str )

#define encodeVarName( coder, var, name )	[(coder) encodeValueOfObjCType:@encode(typeof(var)) at:(void*)&var withName:name];
#define decodeVarName( coder, var, name )	[(coder) decodeValueOfObjCType:@encode(typeof(var)) at:(void*)&var withName:name];

#define encodeArrayName( coder, var, name,elemCount )	[(coder) encodeArrayOfObjCType:@encode(typeof(*var)) count:elemCount at:(void*)var withName:name];
#define decodeArrayName( coder, var, name,elemCount )	[(coder) decodeArrayOfObjCType:@encode(typeof(*var)) count:elemCount at:(void*)var withName:name];

#define decodeVar( coder, var )			decodeVarName( coder, var, #var )
#define encodeVar( coder, var ) 		encodeVarName( coder, var, #var )
#define decodeArray( coder, var,count )		decodeArrayName( coder, var, #var, count )
#define encodeArray( coder, var,count ) 	encodeArrayName( coder, var, #var, count )

@interface NSCoder(NamedCoding)

-(void)encodeObject:anObject withName:aName;
-decodeObjectWithName:aName;
-(void)encodeValueOfObjCType:(const char*)type at:(const void*)var withName:(const char*)name;
-(void)decodeValueOfObjCType:(const char*)type at:(void*)var withName:(const char*)name;
-(void)encodeArrayOfObjCType:(const char*)type count:(long)count at:(const void*)var withName:(const char*)name;
-(void)decodeArrayOfObjCType:(const char*)type count:(long)count at:(void*)var withName:(const char*)name;
-(void)encodeKey:aKey ofObject:anObject;
-(void)decodeKey:aKey ofObject:anObject;


@end

@interface NSObject(reflectiveCoding)


-(void)encodeKeys:keys withCoder:(NSCoder*)aCoder;
-initWithCoder:(NSCoder*)aCoder keys:keys;
+(BOOL)doReflectiveCoding;
+(NSArray*)defaultEncodingKeys;
-(NSArray*)encodingKeys;
-(void)encodeWithCoder:(NSCoder*)aCoder;
-initWithCoder:(NSCoder*)aCoder;
-(NSArray*)theKeysToCopy;
-(void)takeKey:aKey from:otherObject;
-copyReflectivelyWithZone:(NSZone*)aZone;



@end
