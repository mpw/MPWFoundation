//
//  MPWStringTemplate.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 04.02.24.
//

#import "MPWStringTemplate.h"
#import "MPWByteStream.h"
#import "MPWAbstractStore.h"
#import "MPWGenericIdentifier.h"

@interface MPWStringTemplate()

@property(nonatomic,strong) NSArray *fragments;

@end

@implementation MPWStringTemplate

+(NSArray*)parseString:(NSString*)s
{
    //    NSLog(@"writeInterpolatedString: %@ withEnvironment: %@",s,env);
    NSMutableArray *frags=[NSMutableArray array];
    long curIndex=0;
    long maxIndex=[s length];
    while (curIndex < maxIndex) {
        
        NSRange leftBrace=[s rangeOfString:@"{"
                                   options:0
                                     range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( leftBrace.location == NSNotFound ) {
            break;
        }

        if ( leftBrace.location > 0  ) {
            unichar previous = [s characterAtIndex:leftBrace.location-1];
            if( previous == '\\') {
                [frags addObject:[s substringWithRange:NSMakeRange(curIndex, leftBrace.location-curIndex-1)]];
                [frags addObject:@"{"];
                curIndex=leftBrace.location+1;
                continue;
            }
        }
        if ( !isascii([s characterAtIndex:leftBrace.location+1]) ) {
            curIndex=leftBrace.location+1;
            continue;
        }
        [frags addObject:[s substringWithRange:NSMakeRange(curIndex, leftBrace.location-curIndex)]];
        curIndex = leftBrace.location + leftBrace.length + 1;
        NSRange rightBrace=[s rangeOfString:@"}"
                                    options:0
                                      range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( rightBrace.location == NSNotFound ) {
            break;
        }
        curIndex = rightBrace.location + rightBrace.length;
        NSRange varRange=NSMakeRange( leftBrace.location+1, rightBrace.location-leftBrace.location-1);
        NSString *varName=[s substringWithRange:varRange];
        [frags addObject:[MPWGenericIdentifier referenceWithPath:varName]];
//        [self outputString:[s         curIndex = rightBrace.location+1;
    }
    if ( curIndex <= maxIndex ) {
        [frags addObject:[s substringFromIndex:curIndex]];
    }
    return frags;
}

-(instancetype)initWithFragments:(NSArray*)newFrags
{
    self=[super init];
    self.fragments = newFrags;
    return self;
}

CONVENIENCEANDINIT(template, WithString:(NSString*)aString)
{
    return [self initWithFragments:[[self class] parseString:aString]];
}

-(void)writeFragments:(NSArray*)frags onByteStream:(MPWByteStream*)aStream withBindings:env
{
//    NSLog(@"enter writeFragments with frags: %@, bindings: %@",frags,env);
    for (int i=0;i<frags.count;i++ ) {
        id frag = frags[i];
        if ( [frag isKindOfClass:[MPWGenericIdentifier class]]) {
            id value=nil;
            NSString *name=[frag path];
//            NSLog(@"fragment[%d]=%@ path=%@",i,frag,name);
            if ( [name isEqual:@"."]) {
                value=env;
//                NSLog(@"name was period value=%@",value);
            } else if ( [name hasPrefix:@"#"]) {
                name=[name substringFromIndex:1];
                NSMutableArray *fragments=[NSMutableArray array];
                for (int j=i+1;i<frags.count;j++) {
                    //bug: since this steps by one, it also catches string content (non-template) with a / prefix
                    id nestedFrag=frags[j];
                    if ( [nestedFrag isKindOfClass:[MPWGenericIdentifier class]] && [[nestedFrag path] hasPrefix:@"/"] ) {
                        NSAssert2( [[[nestedFrag path] substringFromIndex:1] isEqual:name],@"closing tag '%@' must match opening tag '%@'",frags[j],name);
                        i=j-1;
                        break;
                    }
                    [fragments addObject:nestedFrag];
                }
                //              NSLog(@"sub fragments: %@",fragments);
                id reference = [env referenceForPath:name];
                id array = [name isEqual:@"."] ? env : [env at:reference];
                for (id obj in array ) {
                    //                    NSLog(@"evaluate with %@",obj);
                    [self writeFragments:fragments onByteStream:aStream withBindings:obj];
                }
//                NSLog(@"did write sub now at:[%d] %@, next up is [%d] %@",i,frags[i],i+1,frags[i+1]);
//                NSLog(@"after write sub, result now: %@",[aStream target]);

            } else if ( [name hasPrefix:@"/"]){
                continue;                           // should be filtered out beforehand...
            } else {
                id reference = [env referenceForPath:name];
                value = [env at:reference];
            }
            [aStream writeObject:value];
        } else {
//            NSLog(@"output frag[%d]: %@",i,frag);
            [aStream outputString:frag];
        }
    }
//    NSLog(@"return, result now: %@",[aStream target]);
}

-(void)writeOnByteStream:(MPWByteStream*)aStream withBindings:env
{
    [self writeFragments:self.fragments onByteStream:aStream withBindings:env];
}

-(NSString*)evaluateWith:env
{
    id result=[NSMutableString string];
    @autoreleasepool {
        MPWByteStream *s=[MPWByteStream streamWithTarget:result];
        [self writeOnByteStream:s withBindings:env];
    }
    return result;
}


@end

@implementation NSString(templateEval)

-(NSString*)evaluateAsTemplateWith:env
{
    id result=[NSMutableString string];
    @autoreleasepool {
        MPWStringTemplate *t=[MPWStringTemplate templateWithString:self];
        MPWByteStream *s=[MPWByteStream streamWithTarget:result];
        [t writeOnByteStream:s withBindings:env];
    }
    return result;
}

@end

@implementation NSObject(referenceForPath)

-referenceForPath:aPath { return aPath; }

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWStringTemplate(testing) 


+(void)testNumberOfParsedFragments
{
    INTEXPECT([self templateWithString:@"first {var} second"].fragments.count, 3, @"number of fragments parsed");
}

+(void)testParsedFragments
{
    IDEXPECT([self templateWithString:@"first{var}second"].fragments, (@[@"first",[MPWGenericIdentifier referenceWithPath:@"var"],@"second"]), @"ragments parsed");
}

+(void)testParsedFiveFragments
{
    IDEXPECT([self templateWithString:@"Hello {var} {var2}!"].fragments, (@[@"Hello ",[MPWGenericIdentifier referenceWithPath:@"var"],@" ", [MPWGenericIdentifier referenceWithPath:@"var2"],@"!"]), @"ragments parsed");
}



+(void)testAlwaysStartWithConstantStringEvenIfEmpty
{
    INTEXPECT([self templateWithString:@"{var} second"].fragments.count, 3, @"number of fragments parsed");
}

+(void)testWriteResultWithSubstition
{
    MPWStringTemplate *t=[self templateWithString:@"first {var} second"];
    MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [t writeOnByteStream:output withBindings:@{ @"var": @"value of var"}];
    IDEXPECT( output.target, @"first value of var second",@"substituted");
}

+(void)testSubstituteWholeContext
{
    MPWStringTemplate *t=[self templateWithString:@"first {.} second"];
    MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [t writeOnByteStream:output withBindings:@"single value"];
    IDEXPECT( output.target, @"first single value second",@"substituted");
}

+(void)testIterateOverArrayWithNestedReference
{
    MPWStringTemplate *t=[self templateWithString:@"Array: {#array}Entry {.} {/array}After"];
    MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [t writeOnByteStream:output withBindings:@{@"array": @[ @"First", @"Second", @"Third"  ]}];
    IDEXPECT( output.target, @"Array: Entry First Entry Second Entry Third After", @"collect over array");
}

+(void)testIterateOverArrayWholeContext
{
    MPWStringTemplate *t=[self templateWithString:@"Array: {#.}Entry {.} {/.}After"];
    MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [t writeOnByteStream:output withBindings:@[ @"First", @"Second", @"Third"  ]];
    IDEXPECT( output.target, @"Array: Entry First Entry Second Entry Third After", @"collect over array");
}

+(void)testNonMatchingClosingTagIsCaught
{
    @try {
        MPWStringTemplate *t=[self templateWithString:@"Array: {#array}Entry {.} {/notarray}After"];
        MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
        [t writeOnByteStream:output withBindings:nil];
    } @catch ( NSException* exception ) {
        EXPECTTRUE([[exception reason] containsString:@"closing tag '/notarray' must match opening tag 'array'"],@"the exception we expected");
        return ;
    }
    EXPECTTRUE(false, @"non-matching tags should have raised");
}

+(void)testEvaluateStringAsTemplateDirectly
{
    IDEXPECT( ([@"Array: {#array}Entry {.} {/array}After" evaluateAsTemplateWith:@{@"array": @[ @"First", @"Second", @"Third"  ]}]),@"Array: Entry First Entry Second Entry Third After",@"convenience works");
}

+(void)testOnlyCurlyBracktsTriggerEndProcessing
{
    //  this is for a bugfix, the following template was throwing, with the /b interpreted as a closing tag
    NSString *buggy=@"{#a}{c}/b{/a}";
//    NSString *buggy2=@"{#a}{c}/b{/a}";
    MPWStringTemplate *t=[self templateWithString:buggy];
    IDEXPECT( [t evaluateWith:@{  }],@"",@"");
}

+(void)testEscapeCurlyBraces
{
    IDEXPECT([[self templateWithString:@"\\{var} second"] evaluateWith:@{}] , @"{var} second", @"escaped");
}

+(void)testEscapeNestedCurlyBracesCanGenerateTemplates
{
    NSString *nested=@"{#.}{field}: \\{{field}} {/.}";
    NSArray *fields=@[ @{@"field": @"first" },@{ @"field": @"last"}];
    IDEXPECT([[self templateWithString:nested] evaluateWith:fields] , @"first: {first} last: {last} ", @"escaped");
}


+(NSArray*)testSelectors
{
   return @[
			@"testNumberOfParsedFragments",
            @"testParsedFragments",
            @"testAlwaysStartWithConstantStringEvenIfEmpty",
            @"testWriteResultWithSubstition",
            @"testParsedFiveFragments",
            @"testSubstituteWholeContext",
            @"testIterateOverArrayWholeContext",
            @"testIterateOverArrayWithNestedReference",
//            @"testNonMatchingClosingTagIsCaught",
            @"testEvaluateStringAsTemplateDirectly",
            @"testOnlyCurlyBracktsTriggerEndProcessing",
            @"testEscapeCurlyBraces",
            @"testEscapeNestedCurlyBracesCanGenerateTemplates",
			];
}

@end
