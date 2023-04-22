//
//  MPWSysctlStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.03.23.
//

#import "MPWSysctlStore.h"
#import <sys/sysctl.h>

@implementation MPWSysctlStore

-(id)at:(id<MPWReferencing>)aReference
{
    NSString *name = [[[aReference path] componentsSeparatedByString:@"/"] componentsJoinedByString:@"."];
    char buffer[1024]={0};
    size_t size = 512;
    int retval = sysctlbyname([name UTF8String], buffer, &size, NULL, 0);
    if ( retval < 0) {
        perror("sysctl failed");
    }
//    NSLog(@"at: %@ -> %@ -> %d bytes returned",aReference.path,name,(int)size);
    buffer[size]=0;
    return @(buffer);
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSysctlStore(testing) 

+(void)testRetrieveASpecificSysctl
{
    NSString *expectedHWString=[[[@"sysctl hw.model" resultsOfCommand] lastObject] substringFromIndex:10];
    expectedHWString = [expectedHWString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    MPWSysctlStore *ctl=[MPWSysctlStore store];
    IDEXPECT( ctl[@"hw/model"], expectedHWString,@"HW Model");
}

+(NSArray*)testSelectors
{
   return @[
			@"testRetrieveASpecificSysctl",
			];
}

@end
