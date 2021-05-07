#import <MPWFoundation/MPWDictStore.h>

@interface NSObject(testSelectors)
-(NSArray*)testSelectors;
-testFixture;
@end

static void runTests()
{
	int tests=0;
	int success=0;
	int failure=0;
	NSArray *classes=@[
		@"MPWDictStore",
		@"MPWMappingStore",
		@"MPWCachingStore",
		@"MPWReferenceTests",
		@"MPWFastInvocation",
		@"MPWFilter",
		@"MPWArrayFlattenStream",
		@"MPWFlattenStream",
		@"MPWByteStream",
//		@"MPWTrampoline",
		@"MPWIgnoreUnknownTrampoline",
		@"MPWRESTOperation",
		@"MPWRESTCopyStream",
		@"MPWPoint",
		@"MPWRect",
		@"MPWBlockInvocableTest",
		@"MPWBlockInvocation",
		@"MPWSmallStringTable",
		@"MPWCaseInsensitiveSmallStringTable",
		@"MPWBinaryPlist",
        @"MPWNeXTPListWriter",
//        @"MPWJSONWriter",
//		@"MPWBinaryPListWriter",
		@"MPWIntArray",
		@"MPWRealArray",
		@"MPWSubData",
		@"MPWScanner",
		@"MPWCombinerStream",
        @"MPWMapFilter",
        @"MPWScatterStream",
        @"MPWActionStreamAdapter",
        @"MPWExternalFilter",
        @"MPWSequentialStore",
//      @"MPWFDStreamSource",
        @"MPWPipeline",
        @"MPWEnumFilters",
//        @"MPWBinding",
        @"MPWPathRelativeStore",
        @"NSNumberArithmeticTests",
        @"MPWPropertyBinding",
        @"MPWURLReferenceTests",
        @"MPWDiskStore",
        @"MPWInterval",
//		@"MPWDelimitedTable",
        @"MPWMessageCatcherTesting",

	];

    for (NSString *className in classes ) {
        id testClass=NSClassFromString( className );
        id fixture=testClass;
        if ( fixture ) {
            NSArray *testNames=[testClass testSelectors];
            for ( NSString *testName in testNames ) {
                if ( [testClass respondsToSelector:@selector(testFixture)] ) {
                    fixture=[testClass testFixture];
                }
                SEL testSel=NSSelectorFromString( testName );
                @try {
                    tests++;
                    fprintf(stderr,"                  %s:%s",[className UTF8String],[testName UTF8String]);
                    //                    NSLog(@"%@:%@ -- will test",className,testName);
                    [fixture performSelector:testSel];
                    fprintf(stderr,"\r                                                                              \r");
                    //                    NSLog(@"%@:%@ -- success",className,testName);
                    success++;
                } @catch (NSException *error)  {
                    fprintf(stderr,"\r                                                                              \r");
                    NSString *name=[error name];
                    NSString *reason=[error reason];
                    [failures addObject:[NSString stringWithFormat:@"%@:%@: %@",className,testName,reason]];
                }
            }
        } else {
            tests++;
            [failures addObject:[NSString stringWithFormat:@"error: %@ not found",className]];
        }
        
    }
    printf("\n\033[91;3%dmtests: %d total,  %d successes %d failures\033[0m\n",failures.count > 0 ? 1:2,tests,success,failures.count);
    if (failures.count) {
        printf("\n");
        for (NSString *failure in failures) {
            printf("\033[91;31m%s\033[0m\n",[failure UTF8String]);
        }
    }}

int main( int argc, char *argv[] ) {
	MPWDictStore *a=[MPWDictStore store];
	a[@"hi"]=@"there";
	runTests();
	return 0;

}
