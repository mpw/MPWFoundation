#import <MPWFoundation/MPWDictStore.h>

int main( int argc, char *argv[] ) {
	MPWDictStore *a=[MPWDictStore store];
	a[@"hi"]=@"there";
	NSLog(@"contents: %@",a[@"hi"]);
	return 0;

}
