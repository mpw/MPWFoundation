/* CodingAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

//#define encodeObject( coder, name )  [(coder) encodeObject:name withName:@"##name##"]
//#define decodeObject( coder, name )  name=[[(coder) decodeObjectWithName:@"##name##"] retain]

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
-(void)encodeValueOfObjCType:(const char*)type at:(const void*)theVar withName:(const char*)name;
-(void)decodeValueOfObjCType:(const char*)type at:(void*)theVar withName:(const char*)name;
-(void)encodeArrayOfObjCType:(const char*)type count:(long)count at:(const void*)theVar withName:(const char*)name;
-(void)decodeArrayOfObjCType:(const char*)type count:(long)count at:(void*)theVar withName:(const char*)name;
-(void)encodeKey:aKey ofObject:anObject;
-(void)decodeKey:aKey ofObject:anObject;


@end

@interface NSObject(reflectiveCoding)


-(void)encodeKeys:keys withCoder:(NSCoder*)aCoder;
-decodeWithCoder:(NSCoder*)aCoder keys:keys;
+(BOOL)doReflectiveCoding;
+(NSArray*)defaultEncodingKeys;
-(NSArray*)encodingKeys;
//-(void)encodeWithCoder:(NSCoder*)aCoder;
//-initWithCoder:(NSCoder*)aCoder;
-(NSArray*)theKeysToCopy;
-(void)takeKey:aKey from:otherObject;
-copyReflectivelyWithZone:(NSZone*)aZone;



@end
