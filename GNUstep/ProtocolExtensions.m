#import <objc/Protocol.h>

@implementation Protocol(extensions)

-(BOOL)respondsToSelector:(SEL)sel
{
	return NO;
}

@end
