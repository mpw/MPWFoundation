#import <MPWFoundation/MPWDictStore.h>

static void runTests()
{
	NSArray *classes=@[
		@"MPWDictStore",
	];

	for (NSString *className in classes ) {
		int tests=0;
		int success=0;
		int failure=0;
		id testClass=NSClassFromString( className );
		NSArray *testNames=[testClass testSelectors];
		for ( NSString *testName in testNames ) {
			SEL testSel=NSSelectorFromString( testName );
			@try {
				tests++;
				[testClass performSelector:testSel];
				NSLog(@"%@:%@ -- success",className,testName);
				success++;
			} @catch (id error)  {
				NSLog(@"%@:%@ == failure: %@",className,testName,error);
				failure++;	
			}
		}
		printf("total: %d success: %d failure: %d\n",tests,success,failure);
	}
}

int main( int argc, char *argv[] ) {
	MPWDictStore *a=[MPWDictStore store];
	a[@"hi"]=@"there";
	runTests();
	return 0;

}
