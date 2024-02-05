//
//  MPWStringTemplate.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 04.02.24.
//

#import "MPWStringTemplate.h"
#import "MPWByteStream.h"
#import "MPWAbstractStore.h"

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
        [frags addObject:varName];
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
    for (int i=0;i<frags.count;i+=2 ) {
        [aStream outputString:frags[i]];
        if (i+1 < frags.count ) {
            NSString *name = frags[i+1];
            id value = nil;
            if ( [name isEqual:@"."]) {
                value = env;
            } else if ( [name hasPrefix:@"#"]) {
                name=[name substringFromIndex:1];
                NSMutableArray *fragments=[NSMutableArray array];
                for (int j=i+2;i<frags.count;j++) {
                    if ( [frags[j] hasPrefix:@"/"] ) {
                        NSAssert2( [[frags[j] substringFromIndex:1] isEqual:name],@"closing tag '%@' must match opening tag '%@'",frags[j],name);
                        i=j-1;
                        break;
                    }
                    [fragments addObject:frags[j]];
                }
                NSLog(@"sub fragments: %@",fragments);
                id reference = [env referenceForPath:name];
                id array = [env at:reference];
                for (id obj in array ) {
                    NSLog(@"evaluate with %@",obj);
                    [self writeFragments:fragments onByteStream:aStream withBindings:obj];
                }
                
                continue;
            } else {
                id reference = [env referenceForPath:name];
                value = [env at:reference];
            }
            [aStream writeObject:value];
        }
    }
}

-(void)writeOnByteStream:(MPWByteStream*)aStream withBindings:env
{
    [self writeFragments:self.fragments onByteStream:aStream withBindings:env];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStringTemplate(testing) 


+(void)testNumberOfParsedFragments
{
    INTEXPECT([self templateWithString:@"first {var} second"].fragments.count, 3, @"number of fragments parsed");
}

+(void)testParsedFragments
{
    IDEXPECT([self templateWithString:@"first{var}second"].fragments, (@[@"first",@"var",@"second"]), @"ragments parsed");
}

+(void)testParsedFiveFragments
{
    IDEXPECT([self templateWithString:@"Hello {var} {var2}!"].fragments, (@[@"Hello ",@"var",@" ", @"var2",@"!"]), @"ragments parsed");
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

+(void)testNonMatchingClosingTagIsCaught
{
    @try {
        MPWStringTemplate *t=[self templateWithString:@"Array: {#array}Entry {.} {/notarray}After"];
        MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
        [t writeOnByteStream:output withBindings:@{@"array": @[ @"First", @"Second", @"Third"  ]}];
    } @catch ( NSException* exception ) {
        EXPECTTRUE([[exception reason] containsString:@"closing tag '/notarray' must match opening tag 'array'"],@"the exception we expected");
        return ;
    }
    EXPECTTRUE(false, @"non-matching tags should have raised");
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
            @"testIterateOverArrayWithNestedReference",
            @"testNonMatchingClosingTagIsCaught",
			];
}

@end
