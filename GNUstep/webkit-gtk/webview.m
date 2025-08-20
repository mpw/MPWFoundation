//#include <gtk/gtk.h>
//#include <webkit2/webkit2.h>

#import <Interscript/Interscript.h>
#include <gtk/gtk.h>


int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    ISWebRunner *runner=[ISWebRunner new];
    [runner run];
    return 0;
}

