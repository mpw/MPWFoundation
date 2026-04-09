/* NSObjectAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSObjectAdditions.h"
#import <objc/objc.h>
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
#import <objc/runtime.h>
#else
#import <objc/objc-class.h>
#endif

#ifdef Darwin
#endif

#import <AccessorMacros.h>
#import "MPWByteStream.h"
#import "MPWInstanceVarStore.h"
#import "MPWStructureDefinition.h"

//#import "Foundation/NSDebug.h"


@implementation NSObject(FramweworkPathAdditions)

+(NSString*)frameworkPath:(NSString*)aPath
{
    return [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:aPath];
}

+(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category
{
	NSBundle *bundle=[NSBundle bundleForClass:self];
	id path = [bundle pathForResource:aPath ofType:category];
	if ( path ) {
#ifdef GS_API_LATEST
        return [NSData dataWithContentsOfFile:path]; 
#else
        return [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:nil]; 
#endif
	} else {
//		[NSException raise:@"ResourceUnavailable" format:@"Couldn't find resource '%@' of type '%@' (nil path) for bundle '%@' class %@",aPath,category,bundle,self];
		return nil;
	}
}

-(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category
{
    return [[self class] frameworkResource:aPath category:category];
}


-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    self=[self init];
    for ( NSString *key in [dict allKeys]) {
        [self setValue:dict[key] forKey:key];
    }
    return self;
}

-(instancetype)connectComponents
{
    return self;
}

-(instancetype)initWithDictionaryAndConnect:(NSDictionary *)dict
{
    self=[self initWithDictionary:dict];
    return [self connectComponents];
}



-(instancetype)with:(void (^)(NSObject *self))block {
    if ( block && self) {
        block(self);
    }
    return self;
}

+(instancetype)with:(void (^)(NSObject *self))block {
    return [[self new] with:block];
}

-at:aRefence
{
    NSString *path=[aRefence path];
    return [self valueForKeyPath:path];
}

-(void)at:aRefence put:object
{
    [self setValue:object forKeyPath:[aRefence path]];
}

@end
#import "DebugMacros.h"

@implementation NSObject(testingHelpers)


-value { return self; }

-(void)assertTrue:msg  {   EXPECTTRUE([[self value] boolValue], msg ); }

-(void)assertEqual:other msg:msg  {   IDEXPECT([self value],[other value] , msg ); }

+testFixture
{
    return self;
}

+testSelectors
{
    return [NSArray array];
}


+(void)doTest:(NSString*)testName withTest:test
{
    SEL testMethod=NSSelectorFromString(testName);
    if ( testMethod ) {
        [self performSelector:testMethod];
    } else {
        [NSException raise:@"test-inconsistency" format:@"fixture %@ doesn't respond to test message %@ for test %@",self,NSStringFromSelector(testMethod),[test description]];
    }
}

-(void)doTest:(NSString*)testName withTest:test
{
    SEL testMethod=NSSelectorFromString(testName);
    if ( testMethod ) {
        [self performSelector:testMethod];
    } else {
        [NSException raise:@"test-inconsistency" format:@"fixture %@ doesn't respond to test message %@ for test %@",self,NSStringFromSelector(testMethod),[test description]];
    }
}



@end


@implementation NSObject(ivarAccess)

-rowStore
{
    return [MPWInstanceVarStore storeWithObject:self];
}

+(void)addIvarNamesForCurrentClassToArray:(NSMutableArray*)names
{
	unsigned int i,count=0;
	Ivar* ivars=class_copyIvarList( self, &count );
	for ( i=0;i<count;i++) {
		[names addObject:[NSString stringWithUTF8String:ivar_getName( ivars[i]) ]];
	}
	free(ivars);
}

+(NSString*)ivarNameAtOffset:(int)ivarOffset
{
	unsigned int i,count=0;
	NSString *name=nil;
	Ivar* ivars=class_copyIvarList( self, &count );
	for ( i=0;i<count;i++) {
		if ( ivar_getOffset(ivars[i]) == ivarOffset ) {
			name= [NSString stringWithUTF8String:ivar_getName( ivars[i]) ];
			break;
		}
	}
	free(ivars);
	return name;
}


+(NSMutableArray*)allIvarNames
{
    Class class=self;
    Class superclass=[class superclass];
    NSMutableArray *ivarlist;

    if ( superclass ) {
        ivarlist = [superclass allIvarNames];
        [class addIvarNamesForCurrentClassToArray:ivarlist];
        return ivarlist;
    } else {
        return [NSMutableArray array];
    }
}

+(NSMutableArray*)ivarNames
{
    Class class=self;
    NSMutableArray *ivarlist=[NSMutableArray array];
    [class addIvarNamesForCurrentClassToArray:ivarlist];
    return ivarlist;
}


+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    NSString* name=[self ivarNameAtOffset:ivarOffset];
    if ( !name ) {
        name = [NSString stringWithFormat:@"unnamed_%d",index];
    }
    return name;
}

+(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index ofInstance:(const void*)instaddr
{
    return [self ivarNameAtOffset:(int)(address-instaddr) orIndex:index];
}

-(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index
{
    return [object_getClass(self) ivarNameAtOffset:(int)(address-(const void*)self) orIndex:index];
}



static void __collectInstanceVariablesUntil( Class aClass, NSMutableArray *varNames, Class stopClass )
{
    int i;
    if ( aClass && aClass != stopClass ) {
        unsigned int ivarCount=0;
        Ivar  *ivars=NULL;
        __collectInstanceVariablesUntil( [aClass superclass], varNames ,stopClass );
        
        ivars = class_copyIvarList(aClass, &ivarCount);
        if ( ivars  && ivarCount > 0) {
            for (i=0;i < ivarCount; i++ ){
                Ivar ivar=ivars[i];
                MPWInstanceVariableDefinition *varDescription;
                MPWTypeDefinition *type=[MPWTypeDefinition descriptorForObjcCode:ivar_getTypeEncoding(ivar)[0]];
                varDescription = [[[MPWInstanceVariableDefinition alloc] initWithName:[NSString stringWithCString:ivar_getName(ivar) encoding:NSASCIIStringEncoding]
                                                                               offset:(int)ivar_getOffset(ivar)
                                                                                 type:type]
                                  autorelease];
                [varNames addObject:varDescription];
            }
        }
    }
}

static void __collectInstanceVariables( Class aClass, NSMutableArray *varNames )
{
    return __collectInstanceVariablesUntil(aClass, varNames, nil);
}


static id ivarNameCache=nil;
static id ivarsByClassAndName=nil;



+instanceVariables
{
    NSString *className = NSStringFromClass(self);
    NSMutableArray *varNames;
    if ( !ivarNameCache ) {
        ivarNameCache = [[NSMutableDictionary alloc] init];
    }
    varNames = [ivarNameCache objectForKey:className];
    if ( ! varNames  ) {
        varNames = [NSMutableArray array];
        __collectInstanceVariables( self, varNames );
        [ivarNameCache setObject:varNames forKey:className];
    }
    return varNames;
}

+structure
{
    NSMutableArray *vars=[NSMutableArray array];
    __collectInstanceVariablesUntil( self, vars, [NSObject class] );
    return [MPWStructureDefinition structureWithName:NSStringFromClass(self)  fields:vars];
}

+structureOfThisClass
{
    NSMutableArray *vars=[NSMutableArray array];
    __collectInstanceVariablesUntil( self, vars, [self superclass] );
    return [MPWStructureDefinition structureWithName:NSStringFromClass(self)  fields:vars];
}


static BOOL CreateClassDefinition( const char * name,
                                  Class super_class, NSArray *variables  )
{
    Class class=objc_allocateClassPair(super_class,  name, 0);
    for (MPWInstanceVariableDefinition* ivar in variables) {
        class_addIvar(class, [[ivar name] cStringUsingEncoding:NSASCIIStringEncoding], sizeof(id), log2(sizeof(id)), [[ivar objcType] UTF8String]);
        
    }
    objc_registerClassPair(class);
    return YES;
}



#ifndef __clang_analyzer__
// This 'leaks' because we are installing into the runtime, can't remove after

+(BOOL)createSubclassWithName:(NSString*)className instanceVariableArray:(NSArray*)vars
{
    int len= (int)[className length]+1;
    char *class_name = malloc( len );
    [className getCString:class_name maxLength:len encoding:NSASCIIStringEncoding];
    return CreateClassDefinition( class_name, self , vars );
}

+(BOOL)createSubclassWithName:(NSString*)className instanceVariables:(NSString*)varsAsString
{
    NSArray *varNames=[varsAsString componentsSeparatedByString:@" "];\
    NSMutableArray *variableDefinitions=[NSMutableArray array];
    for ( NSString *name in varNames ) {
        MPWInstanceVariableDefinition *theVar=[[[MPWInstanceVariableDefinition alloc] initWithName:name offset:0 type:[MPWTypeDefinition descriptorForObjcCode:'@']] autorelease];
        [variableDefinitions addObject:theVar];
    }
    return [self createSubclassWithName:className instanceVariableArray:variableDefinitions];
}

#endif

+(BOOL)createSubclassWithName:(NSString*)className
{
    return [self createSubclassWithName:className instanceVariables:@""];
}


+(MPWInstanceVariableDefinition*)ivarForName:(NSString*)name
{
    id className = NSStringFromClass(self);
    id instVarDict=nil;
    if ( !ivarsByClassAndName ) {
        ivarsByClassAndName=[NSMutableDictionary new];
    }
    instVarDict = [ivarsByClassAndName objectForKey:className];
    if ( !instVarDict ) {
        id ivarDefs = [self instanceVariables];
        id names = [[ivarDefs collect] name];
        instVarDict=[NSMutableDictionary dictionaryWithObjects:ivarDefs forKeys:names];
        [ivarsByClassAndName setObject:instVarDict forKey:className];
    }
    return [instVarDict objectForKey:name];
}

@end

@implementation NSObject(methodInstallation)

+(Method)getExistingMethodForMessage:(SEL)messageName
{
    unsigned int methodCount=0;
    Method *methods = class_copyMethodList(self, &methodCount);
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

+(Method)installIMP:(IMP)newIMP withSignature:(const char*)signature selector:(SEL)aSelector oldIMP:(IMP*)oldImpPtr
{
    Method methodDescriptor=NULL;
    if ( self != nil ) {
        methodDescriptor=[self getExistingMethodForMessage:aSelector];
        
        if ( methodDescriptor  && oldImpPtr) {
            IMP old=class_getMethodImplementation(self, aSelector);
            *oldImpPtr = old;
        }
        if ( methodDescriptor ) {
            method_setImplementation(methodDescriptor, newIMP);
        } else {
            if ( class_addMethod(self, aSelector, newIMP, signature )) {
                methodDescriptor=class_getInstanceMethod( self, aSelector);
            }
            
        }
    }
    return methodDescriptor;
}


@end

@implementation NSDictionary(ivarAccess)

+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    if ( index == 1 ) {
        return @"count";
    } else if ( index > 1 ) {
        int isVal = index & 1;
        return isVal ? @"value" : @"key";
    } else {
        return [super ivarNameAtOffset:ivarOffset orIndex:index];
    }
}

-(instancetype)concat:(NSDictionary*)other
{
    NSMutableDictionary *combined=[NSMutableDictionary dictionaryWithDictionary:self];
    for (id key in [other keyEnumerator]) {
        combined[key]=other[key];
    }
    return combined;
}


@end

@implementation NSArray(additions)

+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    if ( index == 1 ) {
        return @"count";
    } else if ( index > 1 ) {
        return @"arrayelement";
    } else {
        return [super ivarNameAtOffset:ivarOffset orIndex:index];
    }
}

@end

@implementation NSData(concat)

-concat:other
{
    NSMutableData *combined = [self mutableCopy];
    [combined appendData:[other asData]];
    return [combined autorelease];
}

@end

@implementation NSObject(memberOfSet1)

-(id)memberOfSet:(NSSet*)aSet
{
    return [aSet member:self];
}

@end

@implementation NSObject(stackCheck)


+(BOOL)isPointerOnStackAboveMe:(void*)ptr within:(long)maxDiff
{
    void *roughlyMyFrame = &_cmd;
    long differenceFromPtr = ptr - roughlyMyFrame;
    return differenceFromPtr > 0 && differenceFromPtr < maxDiff;
}

+(BOOL)isPointerOnStackAboveMe:(void*)ptr
{
    return [self isPointerOnStackAboveMe:ptr within:1000];
}


+(id)isPointerOnStackAboveMeForST:(void*)ptr
{
    return @([self isPointerOnStackAboveMe:ptr]);
}

@end


@implementation NSObject(stprocess)


-main:args
{
    return @(0);
}

-Stdout
{
    return [MPWByteStream Stdout];
}


-(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    [[target do] println:[self each]];
    return 0;
}

+(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    [[[self new] autorelease] runWithStdin:source Stdout:target];
    return 0;
}

+(int)main:args
{
    return [[[[[self alloc] init] autorelease] main:args] intValue];
}

+(int)mainArgc:(int)argc argv:(char**)argv
{
    NSMutableArray *args=[NSMutableArray array];
    [NSClassFromString(@"MPWBlockContext") class];            //
    for (int i=0;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    return [self main:args];
}


@end



@interface NSObjectIvarAcccessTesting : NSObject { id a; int b; float c; NSString *d;id f; }
@end

@implementation NSObject(addressKey)

-addressKey
{
    long long address = (long long)(NSUInteger)self;
    return [NSString stringWithFormat:@"%llu",address];
}

@end

@implementation NSObject(NSDebugEnabled)

static int debugLevel=0;

intAccessor( debugLevel, setDebugLevel )

@end

@implementation NSObjectIvarAcccessTesting : NSObject

+(void)testIvarNames
{
	IDEXPECT( [NSObject allIvarNames], ([NSArray array]), @"NSObject has no visible ivars");
	IDEXPECT( [self allIvarNames], ([NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"f",nil]), @"ivar names");
}

-(char*)addressOfA  { return (char*)&a; };
-(char*)addressOfB  { return (char*)&b; };
-(char*)addressOfC  { return (char*)&c; };
-(char*)addressOfD  { return (char*)&d; };
// -(char*)addressOfE  { return (char*)&e; };
-(char*)addressOfF  { return (char*)&f; };

+(void)testIvarAtOffset
{
	id tester=[[self new] autorelease];
	
	IDEXPECT( [tester ivarNameForVarPointer:[tester addressOfA] orIndex:1],  @"a", @"first ivar" );
	IDEXPECT( [tester ivarNameForVarPointer:[tester addressOfB] orIndex:2],  @"b", @"second ivar" );

//	IDEXPECT( [self ivarNameAtOffset:((char*)&b - (char*)self)], @"b" ,@"name of second ivar");
}



+testSelectors
{
	return @[
			@"testIvarNames",
			@"testIvarAtOffset",
			];
}

@end

@interface NSDictionaryAdditionsTesting : NSObject @end
@implementation NSDictionaryAdditionsTesting

+(void)testConcatDicts
{
    NSDictionary *a=@{ @"a": @(3) };
    NSDictionary *b=@{ @"b": @(12) };
    NSDictionary *combined = [a concat:b];
    INTEXPECT( combined.count,2, @"elements");
    IDEXPECT(combined[@"a"],@(3), @"from a");
    IDEXPECT(combined[@"b"],@(12), @"from a");

}

+testSelectors
{
    return @[
        @"testConcatDicts",
    ];
}

@end
