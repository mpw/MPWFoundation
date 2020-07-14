/* MPWEnumFilter.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#ifdef Darwin
#import <objc/runtime.h>
#import <Foundation/NSInvocation.h>
#import <MPWFoundation/MPWFoundation.h>
#endif
#import "MPWEnumFilter.h"
#import <AccessorMacros.h>
#import "MPWObjectCache.h"
#import "NSInvocationAdditions_lookup.h"
#import "NSObjectFiltering.h"
#import "DebugMacros.h"

@implementation MPWEnumFilters

//#define VERBOSEDEBUG 1

#if VERBOSEDEBUG
static int localDebug=1;
#endif

intAccessor( resultSelector, setResultSelector )
scalarAccessor( id, key , setKey )

//CACHING_ALLOC( quickFilter, 30, NO )

+quickFilter
{
    return [[[self alloc] init] autorelease];
}

-(void)setSource:aSource
{
	[aSource retain];
	[source release];
    source=aSource;
#if VERBOSEDEBUG
    NSLog(@"source: %@",[source class]);
#endif
    if ( [source respondsToSelector:@selector(nextObject)] ) {
        argumentNextObject[0]=(IMP0)[source methodForSelector:@selector(nextObject)];
        variableArgumentIndex[0]=1;
        variableArgumentSource[0]=source;
        variableArguments=1;
        variableArgumentStart=1;
        arguments[1]=argumentNextObject[0]( source, @selector(nextObject));
    } else {
        argumentNextObject[0]=NULL;
        variableArgumentIndex[0]=0;
        variableArgumentSource[0]=nil;
        variableArguments=0;
        variableArgumentStart=0;
        arguments[1]=source;
    }
    targetClass=(Class)nil;
    targetFilterImp=NULL;
}

-init
{
    self = [super init];
    
    return self;
}

-(BOOL)isValid
{
    return arguments[1] != nil;
}


static id returnNil() {  return nil; }

-(void)setInvocation:(NSInvocation*)invocationToForward
{
    int i;
    if ( YES /* invocationToForward != invocation */) {
        id sig = [invocationToForward methodSignature];
        invocation = invocationToForward;
        targetSelector = [invocation selector];
#if 1
        if ( [NSStringFromSelector( targetSelector) hasPrefix:@"__"] ) {
            targetSelector=NSSelectorFromString([NSStringFromSelector( targetSelector) substringFromIndex:2]);
        }
#endif        
#if VERBOSEDEBUG
        if ( localDebug ) {
            NSLog(@"selector = %p",targetSelector);
            NSLog(@"selector = %@",NSStringFromSelector(targetSelector));
			NSLog(@"invocation: %@",invocationToForward);
			NSLog(@"argcount: %d",(int)[sig numberOfArguments]);
        }
#endif
        argumentCount = (int)[sig numberOfArguments];
	
        for (i=2;i<argumentCount;i++) {
			const char *argTypePtr;
                        char argType;
            [invocation getArgument:arguments+i atIndex:i];
#ifdef VERBOSEDEBUG
			NSLog(@"argument %d: %p",i,arguments[i]);
#endif
			argTypePtr = [sig getArgumentTypeAtIndex:i];
			argType = *argTypePtr;
            if ( argType=='@' ) {
                if( [arguments[i] respondsToSelector:@selector(nextObject)]) {
                    argumentNextObject[variableArguments]=(IMP0)[arguments[i] methodForSelector:@selector(nextObject)];
                    variableArgumentIndex[variableArguments]=i;
                    variableArgumentSource[variableArguments]=arguments[i];
                    variableArguments++;
                }
            }
        }
        //---	use existing mechanisms to ensure that iterator with
        //---	no variable arguments is executed at most once
        //---	Issue: if there was a nil arg where there was supposed
        //---	to be an enumerator, we really shouldn't execute at all!

        if ( variableArguments==0 ) {
            argumentNextObject[variableArguments]=(IMP0)returnNil;
            variableArgumentIndex[variableArguments]=0;
            variableArgumentStart=1;
            variableArgumentSource[variableArguments]=nil;
            variableArguments++;
        }
        [invocation setSelector:@selector(filter)];
    }
}

-startFilter
{
    delayedEvaluation=YES;
    return self;
}

-doResult
{
    return nil;    //  this cause nextObject to run within the loop
}

-collectResult
{
    return arguments[0];
}

-selectResult
{
    return arguments[0] ? arguments[resultSelector] : nil;
}

-rejectResult
{
    return arguments[0]==nil ? arguments[resultSelector] : nil;
}

-nextObject
{
    id result=nil;
	id tempTarget;
    do {
        int i;
        for (i=variableArgumentStart;i<variableArguments;i++)
        {
            IMP0 fn = argumentNextObject[i];
            id target = variableArgumentSource[i];

            if (nil== (arguments[variableArgumentIndex[i]] = fn(target,@selector(nextObject))))
            {
                return nil;
            }
        }
        variableArgumentStart=0;
	tempTarget = arguments[1];
//#ifdef Darwin
	if ( key ) {
		tempTarget=[tempTarget valueForKeyPath:key];
	}
//#endif

#if FAST_MSG_LOOKUPS
        CACHED_LOOKUP_WITH_CACHE(tempTarget,targetSelector,targetFilterImp,targetClass );
        arguments[0] = targetFilterImp( tempTarget, targetSelector, arguments[2],arguments[3],arguments[4],arguments[5]);
#elsif !LINUX
        arguments[0] =((IMP)objc_msg_lookup( tempTarget, targetSelector))( tempTarget ,targetSelector ,arguments[2] ,arguments[3] ,arguments[4], arguments[5]);
#else
//#warning slow path!
        targetFilterImp = (IMP0)[tempTarget methodForSelector:targetSelector];
        arguments[0] = ((IMP4)targetFilterImp)( tempTarget, targetSelector, arguments[2],arguments[3],arguments[4],arguments[5]);
#endif
        result = processResult( self, NULL );
    } while ( result == nil );
    return result;
}



-runFilter:(NSInvocation*)newInvocation processingSelector:(SEL)processingSelector
{
    NSMutableArray *result;
    IMP1 arrayAddObject;
    IMP0 selfNextObject=(IMP0)[self methodForSelector:@selector(nextObject)];
    id next;
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"runFilter entered");
    }
#endif
//	NSLog(@"key: %x",key);
//	NSLog(@"key: %@",key);
    result=[NSMutableArray array];
    arrayAddObject=(IMP1)[result methodForSelector:@selector(addObject:)];
    [self setInvocation:newInvocation];
    processResult = (IMP0)[self methodForSelector:processingSelector];
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"got process-result %p",processResult);
    }
#endif
    while (nil!=(next=selfNextObject(self ,@selector(nextObject)) )) {
        arrayAddObject( result, @selector(addObject:), next );
#if VERBOSEDEBUG
        if ( localDebug ) {
            NSLog(@"added result of sending %@ = %@, result now %@",NSStringFromSelector([newInvocation selector]),next,result);
		}
#endif
    }
    invocation=nil;
#if FAST_MSG_LOOKUPS
//    [newInvocation setReturnType:'@'];
#endif
    [newInvocation setReturnValue:&result];
    arguments[1]=nil;
    arguments[0]=nil;
	key=nil;
//	NSLog(@"done key: %x",key);
    [source release]; source= nil;
    return result;
}

-(void)doInvocation:(NSInvocation*)newInvocation
{
    IMP0 selfNextObject=(IMP0)[self methodForSelector:@selector(nextObject)];
    processResult = (IMP0)[self methodForSelector: @selector(doResult)];
    [self setInvocation:newInvocation];
    while (nil!=selfNextObject(self ,@selector(nextObject))) {
    }
    [source release]; source= nil;
}

-collectInvocation:(NSInvocation*)newInvocation
{
#if VERBOSEDEBUG
    if (localDebug ) {
        NSLog(@"collect with invocation %@",newInvocation);
    }
#endif
    return [self runFilter:newInvocation processingSelector:@selector(collectResult)];
}

-selectInvocation:(NSInvocation*)newInvocation
{
    return [self runFilter:newInvocation processingSelector:@selector(selectResult)];
}

-selectFirstInvocation:(NSInvocation*)newInvocation
{
    id result;
    [self setInvocation:newInvocation];
    processResult =(IMP0) [self methodForSelector:@selector(selectResult)];
    resultSelector=1;
    result = [self nextObject];
    invocation=nil;
#if FAST_MSG_LOOKUPS
//    [newInvocation setReturnType:'@'];
#endif
    [newInvocation setReturnValue:&result];
    arguments[1]=nil;
    arguments[0]=nil;
	key=nil;
    //	NSLog(@"done key: %x",key);
    [source release]; source= nil;
    return result;
}

-rejectInvocation:(NSInvocation*)newInvocation
{
    return [self runFilter:newInvocation processingSelector:@selector(rejectResult)];
}

-reduceInvocation:(NSInvocation*)newInvocation
{
    IMP0 selfNextObject=(IMP0)[self methodForSelector:@selector(nextObject)];
    id nextObject;
    processResult =(IMP0) [self methodForSelector:@selector(collectResult)];
    [self setInvocation:newInvocation];

    if ( variableArgumentIndex[0] == 1 ) {
        //--- redirect target of variable arg-stream
        variableArgumentIndex[0]=2;
        //--- swap inital arguments
        if ( arguments[2]==nil ) {
            variableArgumentStart=0;
        } else {
            id temp;
            temp = arguments[1];
            arguments[1]=arguments[2];
            arguments[2]=temp;
        }
    }
    while (nil!=(nextObject=selfNextObject(self ,@selector(nextObject)))) {
        arguments[1]=nextObject;
    }
#if FAST_MSG_LOOKUPS
//    [newInvocation setReturnType:'@'];
#endif
    [newInvocation setReturnValue:&arguments[1]];
    [source release]; source= nil;
    return arguments[1];
}


-(SEL)mapSelector:(SEL)aSelector
{
    NSString *sel=NSStringFromSelector( aSelector );
    if ( [sel hasPrefix:@"__"] ) {
        SEL selector=aSelector;
        selector = NSSelectorFromString( [sel substringFromIndex:2] );
        if ( selector != NULL ) {
            aSelector = selector;
        }
    }
//    NSLog(@"mapped selector %@ to %@",sel,NSStringFromSelector(aSelector));
    return aSelector;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSLog(@"-[%@ respondsToSelector:%@]",[self class],NSStringFromSelector(aSelector));
    BOOL doesRespond;
    doesRespond = arguments[1] ? ([arguments[1] respondsToSelector:aSelector] ||
                           [arguments[1] respondsToSelector:[self mapSelector:aSelector]]):
            YES;
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"respondsToSelector: %@ = %d",NSStringFromSelector(aSelector),doesRespond);
    }
#endif
    return doesRespond; 
}

- (NSMethodSignature *)methodSignatureForHOMSelector:(SEL)aSelector
{
    //--- Return an arbitray message if there is no arguments[1]
    //--- (there were no objects to filter).  Otherwise, we would
    //--- get a runtime error (message not understood) instead of
    //--- an empty return list
    id sig;
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"%@ getting sig for %@",[self class],NSStringFromSelector(aSelector));
    }
    NSLog(@"arguments[1]=%p",arguments[1]);
    NSLog(@"arguments[1]=%@",[arguments[1] class]);
#endif
    if ( arguments[1] ) {
        sig = [arguments[1] methodSignatureForSelector:aSelector];
//		NSLog(@"sig=%x",sig);
        if ( sig == nil ) {
            //--- retry, forcing methods in categories to be
            //--- loaded ( they aren't by methodSignatureForSelector: )
            [arguments[1] methodForSelector:aSelector];
            sig = [arguments[1] methodSignatureForSelector:aSelector];
            if ( sig == nil ) {
                sig = [arguments[1] methodSignatureForSelector:[self mapSelector:aSelector]];
            }
        }
        if ( sig ) {
        } else {
            NSLog(@"couldn't find sig for selector %@ original object %@",NSStringFromSelector(aSelector),arguments[1]);
        }
    } else {
        sig = [NSObject methodSignatureForSelector:@selector(class)];
    }
/*
#if VERBOSEDEBUG
    if ( localDebug ) {
        NSLog(@"sig for %@ = %@/%@ %d",NSStringFromSelector(aSelector),sig,[sig class],[sig methodReturnType]);
    }
#endif
*/
//	NSLog(@"returning sig=%x",sig);
    return sig;
}

-(BOOL)isKindOfClass:(Class)aClass
{
    return [source isKindOfClass:aClass];
}

-description
{
    return [NSString stringWithFormat:@"<MPWEnumFilter %p source=%p (%@)",self,source,source==self?@"self":source];
}

-descriptionWithLocale:aLocal
{
    return [self description];
}



-(void)dealloc
{
	[source release];
	[key release];
	
	[super dealloc];
}

@end


@implementation NSSet(filtering)

-each
{
    return [self objectEnumerator];
}

@end

@implementation MPWEnumFilters(testing)

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"testCollect",@"testCollectALot",@"testEmptyCollect",@"testReverseCollect",
        @"testReduce",@"testReduceWithNilInitial",@"testReverseReduce",@"testSourceRetainCount",
        @"testEmptyArgumentDo",
       @"testSelect",@"testEmptySelect",
		@"testSelectArg",@"testSelectCollect",
		@"testReject",
#if 0
            @"testSelectFirst",
		@"testExpressionSelect",
            @"testWhereValueForKey",@"testLotsOfValueForKey",
#endif		
#ifdef Darwin
#endif
		nil];
}

+(void)testSelect
{
    id array = [NSArray arrayWithObjects:@"fondationBozo",@"foundation",@"foundationHI",@"foundationHI",@"foundation",nil];

    id result =(id)[[array select] __isEqualToString:@"foundationHI"];
    INTEXPECT([result count], 2, @"select number of instances found");
    
}

+(void)testSelectCollect
{
    id array = [NSArray arrayWithObjects:@"fondationBozo",@"foundation",@"foundationHI",@"foundationHI",@"foundation",nil];
	id expected = [NSArray arrayWithObjects:@"foundationHIThere",@"foundationHIThere",nil];

    id result =(id)[[(id)(NSUInteger)[[array select] __isEqualToString:@"foundationHI"] collect] stringByAppendingString:@"There"];
    
    IDEXPECT(result, expected, @"select-collect")
}

+(void)testSelectArg
{
    id array = [NSArray arrayWithObjects:@"fondationBozo",@"foundation",@"foundationHI",@"foundationHI",@"foundation",nil];

    id result =(id)(NSUInteger)[[@"foundationHI" selectArg:1] __isEqualToString:[array each]];
    INTEXPECT([result count], 2, @"select number of instances found");
}

+(void)testEmptySelect
{
    id result = (id)[[[NSArray array] select] __isEqual:@"foundationHI"];
    EXPECTTRUE([result isKindOfClass:[NSArray class]], @"result should be an array");
    INTEXPECT([result count], 0, @"empty");
}

#if 0
+(void)testExpressionSelect
{
    id array = [NSArray arrayWithObjects:@"first.t",@"second.txt",@"third.txt",@"fourth",nil];
    id result;

    result=(id)[[array select] exprValWithSelf:[[[[@"" quote] pathExtension] quote] id_isEqual:@"txt"]];
    INTEXPECT([result count], 2, @"select number of instances found");
}
#endif

+(void)testReject
{
    id array = [NSArray arrayWithObjects:@"fondationBozo",@"foundation",@"foundationHI",@"foundationHI",@"foundation",nil];

    id result =(id)(NSUInteger)[[array reject] __isEqual:@"foundationHI"];
    INTEXPECT([result count], 3, @"number of reject-results");
}


+(void)testReverseCollect
{
    id array = [NSArray arrayWithObjects:@"b",@"c",@"d",nil];
    id testresult = [NSArray arrayWithObjects:@"ab",@"ac",@"ad",nil];

    id result =[[@"a" collect] stringByAppendingString:(id)[array objectEnumerator]];
    IDEXPECT(result, testresult, @"reverse collect");
    
}

+(void)testCollect
{
    id array = [NSArray arrayWithObjects:@"b",@"c",@"d",nil];
    id testresult = [NSArray arrayWithObjects:@"ba",@"ca",@"da",nil];

    id result =[[array collect] stringByAppendingString:@"a"];
    IDEXPECT(result, testresult, @" collect");
}

+(void)testCollectALot
{
    id array = [NSArray arrayWithObjects:@"b",@"c",@"d",nil];
    id testresult = [NSArray arrayWithObjects:@"ba",@"ca",@"da",nil];
    int i;
    for (i=0;i<100;i++ ){
        id pool=[[NSAutoreleasePool alloc] init];
        id result;
        result =[[array collect] stringByAppendingString:@"a"];
        IDEXPECT(result, testresult, @" collect a lot");
        [pool release];
    }
}

+(void)testEmptyCollect
{
    id result = [[[NSArray array] collect] stringByAppendingString:@"a"];
    EXPECTTRUE([result isKindOfClass:[NSArray class]], @"result should be an array");
    INTEXPECT([result count], 0, @"empty collect should have no elements");
}


+(void)testReverseReduce
{
    id array = [NSArray arrayWithObjects:@"b",@"c",@"d",nil];

    id result =[[@"a" reduce] stringByAppendingString:(id)[array each]];
    IDEXPECT(result, @"abcd", @" reduce ");
}

+(void)testReduce
{
    id array = [NSArray arrayWithObjects:@"b",@"c",@"d",nil];

    id result =[[array reduce] stringByAppendingString:@"a"];
    IDEXPECT(result, @"abcd", @" reduce ");
}

+(void)testReduceWithNilInitial
{
    id array = [NSArray arrayWithObjects:@"a",@"b",@"c",@"d",nil];

    id result =[[array reduce] stringByAppendingString:@""];
    IDEXPECT(result, @"abcd", @" reduce ");
}

+(void)testSourceRetainCount
{
#if 0
    id array = [NSArray arrayWithObject:@"a"];
    int retainBefore = [array retainCount];
	int retainAfterJustAnEnumerator;
	
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    [[array objectEnumerator] nextObject];
	[pool drain];
	retainAfterJustAnEnumerator=[array retainCount];
	NSLog(@"retain after just enumerator: %d",retainAfterJustAnEnumerator);
	pool=[[NSAutoreleasePool alloc] init];
    [[array do] self];
	[pool drain];
    NSAssert2( [array retainCount]==retainBefore, @"after do, source's retainCount: %d is not the same as before: %d",[array retainCount], retainBefore);
	pool=[[NSAutoreleasePool alloc] init];
    [[array collect] self];
	[pool drain];
    NSAssert2( [array retainCount]==retainBefore, @"after collect, source's retainCount: %d is not the same as before: %d",[array retainCount], retainBefore);
	pool=[[NSAutoreleasePool alloc] init];
    [[array select] self];
	[pool drain];
    NSAssert2( [array retainCount]==retainBefore, @"after select, source's retainCount: %d is not the same as before: %d",[array retainCount], retainBefore);
#endif
}

+(void)testEmptyArgumentDo
{
    NSMutableString* target=[NSMutableString stringWithString:@""];
    [[target do] appendString:[[NSArray array] each]];
    INTEXPECT([target length], 0, @"empty do");
}

+(void)testWhereValueForKey
{
	id testArray = [NSArray arrayWithObjects:@"hi.txt",@"there.txt",@"not.hi",nil];
	id goodResult =[NSArray arrayWithObjects:@"hi.txt",@"there.txt",nil];
	id testResult =(id)(NSUInteger)[[testArray selectWhereValueForKey:@"pathExtension"] __isEqual:@"txt"];
    IDEXPECT(goodResult, testResult, @"getting .txt pathExtension");
}

+(void)testLotsOfValueForKey
{
	id testArray = [NSArray arrayWithObjects:@"hi.txt",@"there.txt",@"not.hi",nil];
	id goodResult =[NSArray arrayWithObjects:@"hi.txt",@"there.txt",nil];
	int i;
	id testResult;
	id emptyArray=[NSArray array];
	for (i=0;i<100;i++) {
		[[emptyArray do] stringByAppendingString:@""];
	}
	 testResult =(id)(NSUInteger)[[testArray selectWhereValueForKey:@"pathExtension"] __isEqual:@"txt"];
    IDEXPECT(goodResult, testResult, @"getting .txt pathExtension");
}

+(void)testSelectFirst
{
    id testArray = [NSArray arrayWithObjects:@"Mary",@"Joe",@"John",nil];
    IDEXPECT( (id)(NSUInteger)[[testArray selectFirst] __hasPrefix:@"Jo"], @"Joe", @"Joe should be first");
}

@end


