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
		@"MPWBinaryPlist",
        @"MPWNeXTPListWriter",
//        @"MPWJSONWriter",
		@"MPWBinaryPListWriter",
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
        @"MPWValueAccessor",
        @"MPWURLReferenceTests",
//		@"MPWDelimitedTable",

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
//					NSLog(@"%@:%@ -- will test",className,testName);
					[fixture performSelector:testSel];
//					NSLog(@"%@:%@ -- success",className,testName);
					success++;
				} @catch (id error)  {
					NSLog(@"\033[91;31m%@:%@ == error %@\033[0m",className,testName,error);
					failure++;	
				}
			}
		} else {
			tests++;
			failure++;
			NSLog(@"\033[91;31m%@ == class not found\033[0m",className);
		}

	}
	printf("\033[91;3%dmtests: %d total,  %d successes %d failures\033[0m\n",failure>0 ? 1:2,tests,success,failure);
}

int main( int argc, char *argv[] ) {
	MPWDictStore *a=[MPWDictStore store];
	a[@"hi"]=@"there";
	runTests();
	return 0;

}
