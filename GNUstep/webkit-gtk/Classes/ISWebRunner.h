//
// ISWebRunner.h
//


#import <MPWFoundation/MPWFoundation.h>

@interface ISWebRunner : NSObject {

}

@property (nonatomic, strong) id <MPWStorage> store;

-(int)run;

@end
