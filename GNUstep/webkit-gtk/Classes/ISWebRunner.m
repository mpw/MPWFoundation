//
// ISWebRunner.m
//


#import "ISWebRunner.h"

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

@implementation ISWebRunner


-(int)run:(int)argc args:(char **)argv
{
    gtk_init(&argc, &argv);

    // Create main window
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    // Create a WebKit web view
    WebKitWebView *web_view = WEBKIT_WEB_VIEW(webkit_web_view_new());

    // Load a webpage
    gchar *html="<html><body>Hello embedded</body></html>";
    webkit_web_view_load_html (web_view, html , "file:///hello.html" );
//    webkit_web_view_load_uri(web_view, "file:///hello.html");

    // Add the web view to the window
    gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(web_view));

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

@end
