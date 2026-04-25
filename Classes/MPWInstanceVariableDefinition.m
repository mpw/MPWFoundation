//
//  MPWInstanceVariableDefinition.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 04.04.26.
//

#import "MPWInstanceVariableDefinition.h"

@implementation MPWInstanceVariableDefinition

-initWithName:(NSString*)newName offset:(long)newOffset type:(MPWTypeDefinition*)newType
{
    self=[super initWithName:newName type:newType];
    self.offset = newOffset;
    return self;
}

-(NSString*)objcType
{
    return [NSString stringWithFormat:@"%c",self.objcTypeCode];
}

-(unsigned char)objcTypeCode
{
    return self.type.objcTypeCode;
}

#define pointerToVarInObject( anObject )  ((id*)(((char*)anObject) + _offset))

-(void*)pointerToVarRelativeToBase:(void*)base
{
    return pointerToVarInObject(base);
}


-valueInContext:anObject
{
    id result=nil;
    if ( anObject ) {
        //        NSLog(@"ivar %@ get value at offset: %ld",name,offset);
        result= *pointerToVarInObject( anObject );
    }
    return result;
}

-(void)setValue:newValue inContext:anObject
{
    id *ptr = pointerToVarInObject( anObject );
    switch (self.objcTypeCode) {
        case '@':
            if ( anObject &&  *ptr != newValue ) {
                [newValue retain];
                [*ptr release];
                *ptr = newValue;
            }
            break;
        case 'i':
        case 'l':
        case 'b':
        case 'B':
            *(int*)ptr = (int)[newValue integerValue];
            break;
            
    }
    //   NSLog(@"ivar %@ set Value: %@ at offset: %ld",name,newValue,offset);
}

-(NSString*)typeName
{
    return [self.type name];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: name: %@ offset: %ld type: %@>",[self className],self,self.name,self.offset,self.type];
}
@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWInstanceVariableDefinition(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
