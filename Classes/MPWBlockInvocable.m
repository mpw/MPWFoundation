//
//  MPWBlockInvocable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWBlockInvocable.h"
#import "NSNil.h"
#import "MPWRect.h"
#import "MPWBoxerUnboxer.h"

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};



const char *blocksig( void *block_arg )
{
    struct Block_struct *block=(struct Block_struct*)block_arg;
    struct Block_descriptor *descriptor=block->descriptor;
    if ( descriptor) {
        if ( block->flags & BLOCK_HAS_COPY_DISPOSE) {
            return (descriptor->signature);
        } else {
            return (const char*)descriptor->copy_helper;
        }
    }
    return NULL;
}

@implementation MPWBlockInvocable

static struct Block_descriptor sdescriptor= {
		0, 64, NULL, NULL
};

-(id)invokeWithArgs:(va_list)args
{
	return self;
}

-(const char*)ctypes
{
    return blocksig(self);
}

-(NSString*)types
{
    const char *ctypes=[self ctypes];
    return ctypes ? [NSString stringWithCString:ctypes encoding:NSASCIIStringEncoding] : nil;
}
#if TARGET_OS_IPHONE

static id blockFunVar( id self, ... ) {
    va_list args;
    va_start( args, self );
    id result=[self invokeWithArgs:args];
    va_end( args );
    return result;
}

static id blockFun( id self, SEL sel, id arg1, id arg2, id arg3 ) {
    return blockFunVar( self, sel, arg1,arg2,arg3);
}


#else
static id blockFun( id self, ... ) {
	va_list args;
	va_start( args, self );
	id result=[self invokeWithArgs:args];
	va_end( args );
	return result;
}
#endif

-(IMP)invokeMapper
{
	return (IMP)blockFun;
}

-init
{
	self=[super init];
	if ( self ) {
		invoke=(IMP)[self invokeMapper];
		descriptor=&sdescriptor;
        flags=1;
//		flags|=(1 << 28);   // is global
        flags|=(1 << 24);  // we are a heap block
        typeSignature="@@:@@";
	}
	return self;
}

-(id)retain
{
    flags++;
    return self;
}

-(oneway void)release
{
    if ( (--flags &0xffff) <= 0 ) {
        [self dealloc];
    }
}

-(NSUInteger)retainCount
{
    return flags&0xffff;
}

-(NSArray*)formalParameters
{
    return @[];
}

-(const char*)typeSignature
{
    return typeSignature;
}

-invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters
{
    return parameters;
}


-(Method)getMethodForMessage:(SEL)messageName inClass:(Class)aClass
{
    unsigned int methodCount=0;
    Method *methods = class_copyMethodList(aClass, &methodCount);
    Method result=NULL;
    
    if ( methods ) {
        for ( int i=0;i< methodCount; i++ ) {
            if ( method_getName(methods[i]) == messageName ) {
                result = methods[i];
                break;
            }
        }
        free(methods);
    }
    return result;
}

-(IMP)stub
{
    if ( !stub) {
        stub=imp_implementationWithBlock( self );
    }
    return stub;
}

-(Method)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector oldIMP:(IMP*)oldImpPtr
{
    Method methodDescriptor=NULL;
	if ( aClass != nil ) {
		methodDescriptor=[self getMethodForMessage:aSelector inClass:aClass];
		
		if ( methodDescriptor  && oldImpPtr) {
            IMP old=class_getMethodImplementation(aClass, aSelector);
			*oldImpPtr = old;
		}
		if ( methodDescriptor ) {
			method_setImplementation(methodDescriptor, [self stub]);
		} else {
			if ( class_addMethod(aClass, aSelector, [self stub], signature )) {
                methodDescriptor=class_getInstanceMethod( aClass, aSelector);
            }
            
		}
	}
	return methodDescriptor;
}

-(Method)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector
{
    typeSignature=(char*)signature;
    return [self installInClass:aClass withSignature:signature selector:aSelector oldIMP:NULL];
}

-(void)installInClass:(Class)aClass withSignatureString:(NSString*)signatureString selectorString:(NSString*)selectorName
{
#ifndef __clang_analyzer__  
    // analyzer reports leak of signature, we have to leak for runtime structs
    char *signature;
    long siglen=[signatureString length];
    signature = malloc( siglen + 10);
    [signatureString getBytes:signature maxLength:siglen+2 usedLength:NULL encoding:NSASCIIStringEncoding options:0 range:NSMakeRange(0, siglen) remainingRange:NULL];
    signature[siglen]=0;
    [self installInClass:aClass withSignature:(const char*)signature selector:NSSelectorFromString(selectorName)];
#endif
}

static NSString *extractStructType( char *s )
{
    char *start=s;
    int braceCount=0;
    do {
        switch ( *s++ ) {
            case '{':
                braceCount++;
                break;
            case '}':
                braceCount--;
        }
    } while ( *s && braceCount >0);
    
    return [[[NSString alloc] initWithBytes:start length:s-start encoding:NSASCIIStringEncoding] autorelease];

}

-invokeWithTarget:target args:(va_list)args
{
//    NSLog(@"ivokeWithTarget:args:");
	id formalParameters = [self formalParameters];
	id parameters=[NSMutableArray array];
	const char *sig_in=[self typeSignature];
    char signature[128];
    const char *source=sig_in;
    char *dest=signature;

    while ( *source ) {
        if ( !isdigit(*source)  ) {
            *dest++=*source;
        }
        source++;
    }
    *dest++=0;
    int signatureLen=(int)(dest-signature);
	id returnVal;
//    NSLog(@"signature: %s",signature);
    int singleParamSignatureLen=1;
//    NSLog(@"%d parameters",(int)[formalParameters count]);
	for (int i=0,signatureIndex=3;i<[formalParameters count] && signatureIndex<signatureLen;i++,signatureIndex+=singleParamSignatureLen ) {
//        NSLog(@"param[%d]: %c %x",i,signature[i+3],signature[i+3]);
         singleParamSignatureLen=1;
        if ( signature[i+3]==0) {
            NSLog(@"ran off end of signature: %s index: %d, signatureIndex: %d formal parameter count: %d formal parameters: %@",signature,i,signatureIndex,(int)[formalParameters count],formalParameters);
            break;
        }
        id theArg;

		switch ( signature[signatureIndex] ) {
			case ':':{
                
                SEL sel=va_arg( args,SEL);
                theArg = NSStringFromSelector(sel);
				[parameters addObject:theArg];
                break;
            }
			case '@':
			case '#':
				theArg = va_arg( args, id );
                //				NSLog(@"object arg: %@",theArg);
				if ( theArg == nil ) {
					theArg=[NSNil nsNil];
				}
				[parameters addObject:theArg];
				break;
			case 'c':
			case 'C':
			case 's':
			case 'S':
			case 'i':
			case 'I':
			{
				int intArg = va_arg( args, int );
                //				NSLog(@"int param: %d",intArg );
				[parameters addObject:[NSNumber numberWithInt:intArg]];
				break;
			}
			case 'f':
			case 'F':
				[parameters addObject:[NSNumber numberWithFloat:va_arg( args, double )]];
				break;
#if 1
            case '{':
            {
                NSString *structType=extractStructType( signature+signatureIndex);
                singleParamSignatureLen=(int)[structType length];
                id result=nil;
                MPWBoxerUnboxer *boxer = [MPWBoxerUnboxer converterForTypeString:structType];
                if ( boxer ) {
                    result=[boxer boxedObjectForVararg:args];
                }
                if ( result ) {
                    [parameters addObject:result];
                    break;
                }
                
            }
#endif
			default:
                
                [NSException raise:@"unknownparameter" format:@"unhandled parameter at %d '%@'",i,extractStructType( signature+signatureIndex)];
				va_arg( args, void* );

		}
	}
	returnVal = [self invokeOn:target withFormalParameters:formalParameters actualParamaters:parameters];
//    NSLog(@"signature[0]='%c'",signature[0]);
	if ( signature[0] == 'i' ) {
//        NSLog(@"converting to int");
#ifdef __x86_64__
		returnVal=(id)[returnVal longValue];
#else
		returnVal=(id)[returnVal longValue];
#endif
	}
	return returnVal;
}



@end

// #if NS_BLOCKS_AVAILABLE

#import "DebugMacros.h"

@interface MPWBlockInvocableTest : MPWBlockInvocable
{
}

@property (strong) NSArray *formalParameters;

@end

@interface MPWBlockInvocableTest(nonImplementedSignatures)

-(id)doWithInt:(int)intArg;
-(id)doWithFloat:(float)floatArg;
-(id)doWithDouble:(double)doubleArg;
-(id)doWithRect:(NSRect)r;
-(id)doWithPoint:(NSPoint)p;
-(id)doWithSize:(NSSize)p;


@end

@implementation MPWBlockInvocableTest

typedef int (^intBlock)(int arg );
typedef id (^idBlock)(id arg );


-(id)invokeWithArgs:(va_list)args
{
	return (id)(va_arg( args, long ) * 3);
}

-invokeWithTarget:target,...
{
    va_list ap;
    va_start(ap,target);
    id result =[self invokeWithTarget:target args:ap];
    va_end(ap);

    return result;
}


+(void)testBlockInvoke
{
	id blockObj = [[[self alloc] init] autorelease];
	INTEXPECT( ((intBlock)blockObj)( 3 ), 9, @"block(3) ");
}
    
+(void)testNSBlockTypes
{
    intBlock myBlock=^(int arg){ return 3; };
    const char *csig = blocksig( myBlock);
    NSString *sig=[NSString stringWithCString:csig encoding:NSASCIIStringEncoding];
    IDEXPECT(sig, @"i12@?0i8", @"signature of int->int block");
}


+(void)testBlockCopy
{
    id blockObj = [[[self alloc] init] autorelease];
    intBlock firstBlock=(intBlock)blockObj;
    intBlock copiedBlock=Block_copy(firstBlock);
    INTEXPECT( ((intBlock)copiedBlock)( 3 ), 9, @"block(3) ");
    Block_release(copiedBlock);
}


+(void)testIntArg
{
    MPWBlockInvocableTest *invocable=[[self new] autorelease];
    
    [invocable installInClass:self withSignature:"v@:i" selector:@selector(doWithInt:)];
    [invocable setFormalParameters:@[ @"anInt" ] ];
    id args=[invocable invokeWithTarget:invocable,42];
    INTEXPECT([args count], 1, @"number of args");
    IDEXPECT([args firstObject], @(42), @"integer arg");
}

+(void)testDoubleArg
{
    MPWBlockInvocableTest *invocable=[[self new] autorelease];
    
    [invocable installInClass:self withSignature:"v@:f" selector:@selector(doWithDouble:)];
    [invocable setFormalParameters:@[ @"aDouble" ] ];
    id args=[invocable invokeWithTarget:invocable,42.74];
    INTEXPECT([args count], 1, @"number of args");
    
    INTEXPECT((int)([[args firstObject] doubleValue]* 100.0), 4274, @"double arg");
}

+(void)testRectArg
{
    MPWBlockInvocableTest *invocable=[[self new] autorelease];
    char encodeString[130]="v@:";
    strcat(encodeString,@encode(NSRect));
    [invocable installInClass:self withSignature:encodeString selector:@selector(doWithRect:)];
    [invocable setFormalParameters:@[ @"aRect" ] ];
    NSArray* args=[invocable invokeWithTarget:invocable,NSMakeRect(2,12, 42, 52)];
    INTEXPECT([args count], 1, @"number of args");
    MPWRect *rectArg=[args firstObject];
    FLOATEXPECTTOLERANCE([rectArg x], 2, 0.0001, @"x");
    FLOATEXPECTTOLERANCE([rectArg y], 12, 0.0001, @"y");
    FLOATEXPECTTOLERANCE([rectArg width], 42, 0.0001, @"width");
    FLOATEXPECTTOLERANCE([rectArg height], 52, 0.0001, @"height");
}


+(void)testPointArg
{
    MPWBlockInvocableTest *invocable=[[self new] autorelease];
    char encodeString[130]="v@:";
    strcat(encodeString,@encode(NSPoint));
    [invocable installInClass:self withSignature:encodeString selector:@selector(doWithPoint:)];
    [invocable setFormalParameters:@[ @"aPoint" ] ];
    NSArray* args=[invocable invokeWithTarget:invocable,NSMakePoint(203,120)];
    INTEXPECT([args count], 1, @"number of args");
    MPWPoint *pointArg=[args firstObject];
    FLOATEXPECTTOLERANCE([pointArg x], 203, 0.0001, @"x");
    FLOATEXPECTTOLERANCE([pointArg y], 120, 0.0001, @"y");
}

+(void)testSizeArg
{
    MPWBlockInvocableTest *invocable=[[self new] autorelease];
    
    char encodeString[130]="v@:";
    strcat(encodeString,@encode(NSPoint));
    [invocable installInClass:self withSignature:encodeString selector:@selector(doWithSize:)];
    [invocable setFormalParameters:@[ @"aPoint" ] ];
    NSArray* args=[invocable invokeWithTarget:invocable,NSMakeSize(283,9991)];
    INTEXPECT([args count], 1, @"number of args");
    MPWPoint *pointArg=[args firstObject];
    FLOATEXPECTTOLERANCE([pointArg x], 283, 0.0001, @"x");
    FLOATEXPECTTOLERANCE([pointArg y], 9991, 0.0001, @"y");
}

-(void)dealloc
{
    [_formalParameters release];
    [super dealloc];
}

+testSelectors
{
	return [NSArray arrayWithObjects:
           @"testBlockInvoke",
            @"testNSBlockTypes",
            @"testBlockCopy",
            @"testIntArg",
            @"testDoubleArg",
            @"testRectArg",
            @"testPointArg",
            @"testSizeArg",
			nil];
}

@end


//#endif
