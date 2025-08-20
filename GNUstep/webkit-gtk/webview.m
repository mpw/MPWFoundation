//#include <gtk/gtk.h>
//#include <webkit2/webkit2.h>

#import <Interscript/Interscript.h>
#import <MPWFoundation/MPWFoundation.h>
#include <gtk/gtk.h>

@interface ConstantStore : MPWAbstractStore {
    
}
@end
@implementation ConstantStore

-get:ref
{
    return @"<html><body>GET scheme handler from store delegate</body></html>";
}

@end


int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    ISWebRunner *runner=[ISWebRunner new];
    runner.store = [ConstantStore store];
    [runner run];
    return 0;
}

