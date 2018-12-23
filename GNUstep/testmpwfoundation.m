#import <MPWFoundation/MPWDictStore.h>

@interface NSObject(testSelectors)
-(NSArray*)testSelectors;
@end

static void runTests()
{
	int tests=0;
	int success=0;
	int failure=0;
	NSArray *classes=@[
		@"MPWDictStore",
		@"MPWReferenceTests",
		@"MPWFastInvocation",
		@"MPWFilter",
		@"MPWArrayFlattenStream",
		@"MPWFlattenStream",
		@"MPWByteStream",

	];

	for (NSString *className in classes ) {
		id testClass=NSClassFromString( className );
		if (testClass ) {
			NSArray *testNames=[testClass testSelectors];
			for ( NSString *testName in testNames ) {
				SEL testSel=NSSelectorFromString( testName );
				@try {
					tests++;
					[testClass performSelector:testSel];
					NSLog(@"%@:%@ -- success",className,testName);
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
