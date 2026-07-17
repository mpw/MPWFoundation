//
//  AppDelegate.m
//  TestMPWFoundation
//
//  Created by Marcel Weiher on 12/7/16.
//
//

#import "ViewBuilderAppDelegate.h"
#import <Foundation/Foundation.h>
#import <objc/message.h>

@interface NSObject (MPWEmbeddedTests)
+ (NSArray *)testSelectors;
+ (id)testFixture;
@end

@interface ViewBuilderAppDelegate ()

@end

@implementation ViewBuilderAppDelegate


int runTests( NSArray *testSuiteNames , NSArray *testTypeNames,  BOOL verbose ,BOOL veryVerbose ) {
    NSString *testListPath=[[NSBundle mainBundle] pathForResource:@"ClassesToTest"
                                                           ofType:@"plist"];
    NSData *namePlist=[NSData dataWithContentsOfFile:testListPath];
    NSArray *classNamesToTest=[NSPropertyListSerialization propertyListWithData:namePlist options:0 format:0 error:nil];
    NSArray *arguments=NSProcessInfo.processInfo.arguments;
    NSUInteger classArgument=[arguments indexOfObject:@"--classes"];
    if (classArgument != NSNotFound && classArgument + 1 < arguments.count) {
        classNamesToTest=[arguments[classArgument + 1] componentsSeparatedByString:@","];
    }
    NSUInteger total=0;
    NSUInteger failures=0;
    for ( NSString *className in classNamesToTest ) {
        Class testClass=NSClassFromString(className);
        if (!testClass) {
            fprintf(stderr,"MPW TEST FAILURE: missing class %s\n",className.UTF8String);
            failures++;
            continue;
        }
        NSArray *selectors=[testClass respondsToSelector:@selector(testSelectors)] ? [testClass testSelectors] : @[];
        for (NSString *selectorName in selectors) {
            total++;
            id fixture=[testClass respondsToSelector:@selector(testFixture)] ? [testClass testFixture] : testClass;
            @try {
                SEL selector=NSSelectorFromString(selectorName);
                ((void (*)(id,SEL))objc_msgSend)(fixture,selector);
            } @catch (NSException *exception) {
                failures++;
                fprintf(stderr,"MPW TEST FAILURE: %s.%s: %s\n",
                        className.UTF8String,selectorName.UTF8String,exception.reason.UTF8String);
            }
        }
    }
    fprintf(stderr,"MPW TEST RESULT: %lu tests, %lu failures\n",(unsigned long)total,(unsigned long)failures);
    return failures ? 1 : 0;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    int result=runTests( @[ @"MPWFoundation"], @[] , NO, NO);
    exit(result);
    return YES;
}


@end
