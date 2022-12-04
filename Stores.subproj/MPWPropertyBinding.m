//
//  MPWPropertyBinding.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/6/12.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWPropertyBinding.h"
#import <AccessorMacros.h>
#import <Foundation/Foundation.h>
#import <MPWFoundation/MPWByteStream.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    Class   targetClass;
    int     targetOffset;
    SEL     getSelector,putSelector;
    IMP0    getIMP;
    IMP1    putIMP;
    id      additionalArg;
    char    objcType;
} AccessPathComponent;


@implementation MPWPropertyBinding
{
    id target;
    AccessPathComponent components[6];
    int count;
    id name;
}

idAccessor(target, _setTarget)

//extern id objc_msgSend(id, SEL, ...);

+valueForName:(NSString*)name
{
    return [[[self alloc] initWithName:name] autorelease];
}

-(NSString*)putSelectorStringForName:(NSString*)newName
{
    return [[[@"set" stringByAppendingString:[[newName substringToIndex:1] capitalizedString]]  stringByAppendingString:[newName substringFromIndex:1]]stringByAppendingString:@":"];
}

-(void)setName:(NSString*)newName forComponent:(AccessPathComponent*)component
{
    component->getSelector= NSSelectorFromString(newName);
    component->putSelector=NSSelectorFromString([self putSelectorStringForName:newName]);
    component->getIMP=(IMP0)objc_msgSend;
    component->putIMP=(IMP1)objc_msgSend;
    component->objcType='@';
    component->targetOffset=-1;
    component->additionalArg=[newName retain];
}

-(void)bindComponent:(AccessPathComponent*)component toTargetClass:(Class)targetClass
{
    component->targetClass=targetClass;
    if ( ![targetClass instancesRespondToSelector:component->getSelector] ) {
        component->getSelector = @selector(objectForKey:);
    }
    component->getIMP=(IMP0)[targetClass instanceMethodForSelector:component->getSelector];

    if ( ![targetClass instancesRespondToSelector:component->putSelector] ) {
        component->putSelector = @selector(setObject:forKey:);
    }
    if ( ![targetClass instancesRespondToSelector:component->putSelector] ) {
        component->putSelector = @selector(setValue:forKey:);
    }
    component->putIMP=(IMP1)[targetClass instanceMethodForSelector:component->putSelector];
    if ( (component->getIMP == NULL) || (component->putIMP == NULL) ) {
        [NSException raise:@"bind failed" format:@"MPWropertyBinding bind failed for %@, getImp %p putSelector: %@ putImp: %p targetClass: %@",self,component->getIMP,NSStringFromSelector(component->putSelector),component->putIMP,targetClass];
    }
    NSMethodSignature *sig=[targetClass instanceMethodSignatureForSelector:component->getSelector];
    const char *typeString=[sig methodReturnType];
    if ( typeString) {
        component->objcType=typeString[0];
    } else {
        component->objcType='@';
    }
}

-(void)bindComponent:(AccessPathComponent*)component toTarget:aTarget
{
    [self bindComponent:component toTargetClass: object_getClass( aTarget)];
}

-(void)setComponentsForPath:(NSArray*)pathComponents
{
    int componentCount=(int)[pathComponents count];
    NSAssert1(componentCount<6, @"only support up to 6 path components got %d", componentCount);
    count=componentCount;
    for (int i=0;i<count;i++) {
        [self setName:[pathComponents objectAtIndex:i] forComponent:components+i];
    }
}
idAccessor(name, setName)

-initWithPath:(NSString*)path
{
    self=[super init];
    if ( self ) {
        [self setName:path];
        [self setComponentsForPath:[path componentsSeparatedByString:@"/"]];
        value=[self methodForSelector:@selector(value)];
    }
    return self;
}

-initWithName:(NSString*)newName
{
    return [self initWithPath:newName];
}

static inline bool isInteger( AccessPathComponent c  )
{
    return c.objcType=='q' || c.objcType=='l'|| c.objcType=='i' || c.objcType=='B';
}


static inline id getValueForComponents( id currentTarget, AccessPathComponent *c , int count) {
    for (int i=0;i<count;i++) {
        //        if ( c[i].targetOffset>= 0 ) {
        //            currentTarget=(id)((unsigned char*)currentTarget + c[i].targetOffset);
        //        } else {
        if ( c[i].objcType == '@' ) {
            currentTarget=((IMP1)c[i].getIMP)( currentTarget, c[i].getSelector, c[i].additionalArg );
        } else if  ( isInteger( c[i] ) ) {
            currentTarget=@((long)((IMP1)c[i].getIMP)( currentTarget, c[i].getSelector, c[i].additionalArg ));
        } else {
            currentTarget = nil;
        }
        //        }
    }
    return currentTarget;
}


static inline long getIntValueForComponents( id currentTarget, AccessPathComponent *c , int count) {
    long result = 0;
        //        if ( c[i].targetOffset>= 0 ) {
        //            currentTarget=(id)((unsigned char*)currentTarget + c[i].targetOffset);
        //        } else {
        if ( c[0].objcType == '@' ) {
            result=[((IMP1)c[0].getIMP)( currentTarget, c[0].getSelector, c[0].additionalArg ) integerValue];
        } else if  ( isInteger( c[0] ) ) {
            result=((long)((IMP1)c[0].getIMP)( currentTarget, c[0].getSelector, c[0].additionalArg ));

        }
        //        }
    return result;
}

static inline void setValueForComponents( id currentTarget, AccessPathComponent *c , int count, id value) {
    currentTarget = getValueForComponents( currentTarget, c, count-1);
    int final=count-1;
    if (  isInteger( c[final] )) {
        ((IMP2)c[final].putIMP)( currentTarget, c[final].putSelector, (id)[value integerValue], c[final].additionalArg );
    } else {
        ((IMP2)c[final].putIMP)( currentTarget, c[final].putSelector,value , c[final].additionalArg );
    }
}

static inline void setIntValueForComponents( id currentTarget, AccessPathComponent *c , int count, long value) {
    currentTarget = getValueForComponents( currentTarget, c, count-1);
    int final=count-1;
    if (  isInteger( c[final] ) ) {
        ((IMP2)c[final].putIMP)( currentTarget, c[final].putSelector, (void*)value, c[final].additionalArg );
    } else {
        ((IMP2)c[final].putIMP)( currentTarget, c[final].putSelector, @(value), c[final].additionalArg );
    }
}

-(void)_setOffset:(int)offset
{
    components[0].targetOffset=offset;
}

-(void)bindToTarget:aTarget
{
    [self _setTarget:aTarget];
    id currentTarget=aTarget;
    for ( int i=0;i<count;i++) {
        [self bindComponent:components+i toTarget:currentTarget];
        currentTarget=getValueForComponents(currentTarget, components+i, 1);
    }
}

-(void)bindToClass:(Class)aClass
{
    [self bindComponent:components toTargetClass:aClass];
}

-valueForTarget:aTarget
{
    return getValueForComponents( aTarget, components, count);
}

-(long)integerValueForTarget:aTarget
{
    return getIntValueForComponents( aTarget, components, count);
}

-(long)integerValue
{
    return getIntValueForComponents( self->target, components, count);
}

-(void)setValue:newValue forTarget:aTarget
{
     setValueForComponents( aTarget, components, count,newValue);
}


-value {  return getValueForComponents( target, components, count); }

-(void)setValue:newValue
{
    setValueForComponents( target, components, count,newValue);
}

-(void)setIntValue:(long)newValue
{
    setIntValueForComponents( target, components, count,newValue);
}

-(void)setIntValue:(long)newValue forTarget:(id)aTarget
{
    setIntValueForComponents( aTarget, components, count,newValue);
}

-(char)typeCode
{
    return components[0].objcType;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p targetClass: %@ name: %@>",self.class,self,components[0].targetClass,name];
}

@end

#import "DebugMacros.h"
#import <MPWByteStream.h>
#import "MPWRusage.h"

@interface MPWPropertyBindingTestingClass:NSObject

@property (nonatomic,assign) long number;
@property (nonatomic,strong) NSString* string;
@property (nonatomic,strong) id target;

@end

@implementation MPWPropertyBindingTestingClass

-(void)dealloc {
    [_string release];
    [_target release];
    [super dealloc];
}

-(BOOL)isEqual:(MPWPropertyBindingTestingClass*)other
{
    return self.number == other.number &&
          (self.string == other.string  ||
           [self.string isEqual: other.string]) &&
          (self.target == other.target  ||
           [self.target isEqual: other.target]);
}

@end




@implementation MPWPropertyBinding(testing)

+(MPWPropertyBindingTestingClass*)_testTarget
{
    MPWPropertyBindingTestingClass *t=[[MPWPropertyBindingTestingClass new] autorelease];
    t.string=@"hello";
    t.number=34;
    return t;
}


+(MPWPropertyBindingTestingClass*)_testCompoundTarget
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    t.target=[self _testTarget];
    return t;
}

+(void)testBasicUnboundAccess
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"string"];
    IDEXPECT([accessor valueForTarget:t], @"hello", @"objectValue");
}


+(void)testBoundDictAccess
{
    NSDictionary *dict=[[@{ @"hello": @"world" } mutableCopy] autorelease];
    MPWPropertyBinding *accessor=[self valueForName:@"hello"];
    [accessor bindToTarget:dict];
    IDEXPECT([accessor value], @"world", @"hello -> world");
}

+(void)testBasicUnboundSetAccess
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"string"];
    [accessor setValue:@"newString" forTarget:t];
    IDEXPECT(t.string, @"newString", @"objectValue");
}


+(void)testBoundGetSetAccess
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"string"];
    [accessor bindToTarget:t];
    IDEXPECT([accessor value], @"hello", @"target after bind");
    [accessor setValue:@"world"];
    IDEXPECT(t.string, @"world", @"newly set target after bind");
}

+(void)testPathAccess
{
    MPWPropertyBindingTestingClass *t=[self _testCompoundTarget];
    MPWPropertyBinding *accessor=[[[self alloc] initWithPath:@"target/string"] autorelease];
    [accessor bindToTarget:t];
    IDEXPECT([accessor value], @"hello", @"target after bind");
    [accessor setValue:@"pathString"];
    IDEXPECT([[t target] string], @"pathString", @"newly set target after bind");
}

#define ACCESS_COUNT  10000

+(void)testPerformanceOfPathAccess
{
    NSString *keyPath=@"target/string";
    MPWPropertyBindingTestingClass *t=[self _testCompoundTarget];
    MPWRusage* accessorStart=[MPWRusage current];
    MPWPropertyBinding *accessor=[[[self alloc] initWithPath:keyPath] autorelease];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [accessor valueForTarget:t];
    }
    MPWRusage* accessorTime=[MPWRusage timeRelativeTo:accessorStart];
    MPWRusage* boundAccessorStart=[MPWRusage current];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [accessor valueForTarget:t];
    }
    MPWRusage* boundAccessorTime=[MPWRusage timeRelativeTo:boundAccessorStart];
    accessor=[[[self alloc] initWithPath:keyPath] autorelease];
    [accessor bindToTarget:t];
    MPWRusage* kvcStart=[MPWRusage current];
    for (int i=0;i<ACCESS_COUNT;i++) {
        [t valueForKeyPath:@"target.target"];
    }
    MPWRusage* kvcTime=[MPWRusage timeRelativeTo:kvcStart];
    double unboundRatio = (double)[kvcTime userMicroseconds] / (double)[accessorTime userMicroseconds];
#define EXPECTEDUNBOUNDRATIO 9
    
    EXPECTTRUE(unboundRatio > EXPECTEDUNBOUNDRATIO, ([NSString stringWithFormat:@"ratio of value accessor to kvc path %g < %g",
                                                      unboundRatio,(double)EXPECTEDUNBOUNDRATIO]));

    
//    NSLog(@"unboundRatio: %g %d iterations raw KVC: %ld raw accessor: %ld",unboundRatio,ACCESS_COUNT,[kvcTime userMicroseconds],[accessorTime userMicroseconds]);
    double boundRatio = (double)[kvcTime userMicroseconds] / (double)[boundAccessorTime userMicroseconds];
//    NSLog(@"boundRatio: %g %d iterations raw KVC: %ld raw accessor: %ld",boundRatio,ACCESS_COUNT,[kvcTime userMicroseconds],[boundAccessorTime userMicroseconds]);
#define EXPECTEDBOUNDRATIO 10
    EXPECTTRUE(unboundRatio > EXPECTEDBOUNDRATIO, ([NSString stringWithFormat:@"ratio of bound value accessor to kvc path %g < %g",
                                                      boundRatio,(double)EXPECTEDBOUNDRATIO]));
    

    
}


+(void)testReadAccessOfIntegerIvar
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToTarget:t];
    IDEXPECT( [accessor value], @(34), @"integer value");
}


+(void)testIntReadAccessOfIntegerIvar
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToTarget:t];
    INTEXPECT( [accessor integerValue], 34, @"integer value");
}

+(void)testIntWriteAccessOfIntegerIvar
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToTarget:t];
    [accessor setIntValue:45];
    INTEXPECT( [t number], 45, @"integer value");
    [accessor setValue:@"200"];
    INTEXPECT( [t number], 200, @"integer value set as string");
    [accessor setValue:@(100)];
    INTEXPECT( [t number], 100, @"integer value set as NSNumber");
}

+(void)testTypeOfIntVar
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToTarget:t];
    char typeCode=[accessor typeCode];
    if ( sizeof(long)==8) {
        INTEXPECT(typeCode, 'q', @"type");
    } else {
        INTEXPECT(typeCode, 'l', @"type");
    }
}

+(void)testIntegerValueForTarget
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToClass:t.class];
    INTEXPECT( [accessor integerValueForTarget:t], 34, @"integer value");
}

+(void)testObjectValueForTarget
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"string"];
    [accessor bindToClass:t.class];
    IDEXPECT( [accessor valueForTarget:t], @"hello", @"object value");
}

+(void)testObjectValueForIntIVar
{
    MPWPropertyBindingTestingClass *t=[self _testTarget];
    MPWPropertyBinding *accessor=[self valueForName:@"number"];
    [accessor bindToClass:t.class];
    IDEXPECT( [accessor valueForTarget:t], @(34), @"object value");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testBasicUnboundAccess",
            @"testBasicUnboundSetAccess",
            @"testBoundGetSetAccess",
            @"testPathAccess",
            @"testPerformanceOfPathAccess",
            @"testBoundDictAccess",
            @"testReadAccessOfIntegerIvar",
            @"testIntReadAccessOfIntegerIvar",
            @"testIntWriteAccessOfIntegerIvar",
            @"testTypeOfIntVar",
            @"testIntegerValueForTarget",
            @"testObjectValueForTarget",
            @"testObjectValueForIntIVar",
            nil];
}

@end
