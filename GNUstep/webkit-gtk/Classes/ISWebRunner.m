//
// ISWebRunner.m
//


#import "ISWebRunner.h"

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

@implementation ISWebRunner


-(void)webkitRequest:(WebKitURISchemeRequest *)request
{
    const char *uri = webkit_uri_scheme_request_get_uri(request);
    const char *method = webkit_uri_scheme_request_get_http_method(request);
    SoupMessageHeaders *headers = webkit_uri_scheme_request_get_http_headers(request);
    GInputStream *body_stream = webkit_uri_scheme_request_get_http_body(request);
    NSString *uristring = @(uri);
    g_print("Intercepted request: %s %s\n", method, uri);
    
    // Handle different HTTP methods
    if (g_strcmp0(method, "GET") == 0) {
        [self get:request uri:uristring];
    }
    else if (g_strcmp0(method, "POST") == 0) {
        handle_post_request(request, uri, body_stream);
    }
    else if (g_strcmp0(method, "PUT") == 0) {
        handle_put_request(request, uri, body_stream);
    }
    else {
        // Handle other methods or return 405 Method Not Allowed
        send_error_response(request, 405, "Method Not Allowed");
    }
}

static void
custom_scheme_handler(WebKitURISchemeRequest *request, gpointer user_data)
{
    [(ISWebRunner*)user_data webkitRequest:request];
}

-(void)get:(WebKitURISchemeRequest *)request uri:(NSString*)uristring
{
    const char *response_data;
    const char *content_type;
 
    NSString *resultstring = [self.store get:uristring];

    response_data=[resultstring UTF8String];
        content_type = "text/html";

    
    // Create response stream
    GInputStream *stream = g_memory_input_stream_new_from_data(
        g_strdup(response_data), strlen(response_data), g_free);
    
    webkit_uri_scheme_request_finish(request, stream, strlen(response_data), content_type);
    g_object_unref(stream);
}

static void
handle_post_request(WebKitURISchemeRequest *request, const char *uri, GInputStream *body_stream)
{
    if (!body_stream) {
        send_error_response(request, 400, "Bad Request - No body");
        return;
    }
    
    // Read the request body
    GError *error = NULL;
    gsize bytes_read;
    char buffer[4096];
    GString *body_data = g_string_new("");
    
    while (TRUE) {
        bytes_read = g_input_stream_read(body_stream, buffer, sizeof(buffer) - 1, NULL, &error);
        if (error) {
            g_print("Error reading request body: %s\n", error->message);
            g_error_free(error);
            break;
        }
        if (bytes_read == 0) break;
        
        buffer[bytes_read] = '\0';
        g_string_append(body_data, buffer);
    }
    
    g_print("POST body: %s\n", body_data->str);
    
    // Process the POST data (e.g., parse JSON, save to database, etc.)
    const char *response = "{\"result\": \"success\", \"received\": true}";
    
    GInputStream *stream = g_memory_input_stream_new_from_data(
        g_strdup(response), strlen(response), g_free);
    
    webkit_uri_scheme_request_finish(request, stream, strlen(response), "application/json");
    
    g_object_unref(stream);
    g_string_free(body_data, TRUE);
}

static void
handle_put_request(WebKitURISchemeRequest *request, const char *uri, GInputStream *body_stream)
{
    // Similar to POST handling, but for PUT semantics
    g_print("PUT request to: %s\n", uri);
    
    const char *response = "{\"result\": \"updated\"}";
    GInputStream *stream = g_memory_input_stream_new_from_data(
        g_strdup(response), strlen(response), g_free);
    
    webkit_uri_scheme_request_finish(request, stream, strlen(response), "application/json");
    g_object_unref(stream);
}

static void
send_error_response(WebKitURISchemeRequest *request, int status_code, const char *reason)
{
    char *error_json = g_strdup_printf("{\"error\": %d, \"message\": \"%s\"}", 
                                      status_code, reason);
    
    GInputStream *stream = g_memory_input_stream_new_from_data(
        error_json, strlen(error_json), g_free);
    
    webkit_uri_scheme_request_finish(request, stream, strlen(error_json), "application/json");
    g_object_unref(stream);
}


-(int)run
{

    // Create main window
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    WebKitWebContext *context = webkit_web_context_get_default();
    
    // Register custom scheme handler for "myapp://" URLs
    webkit_web_context_register_uri_scheme(
        context,
        "myapp",                    // scheme name
        custom_scheme_handler,      // callback function
        self,                       // user_data
        NULL                        // destroy_notify
    );


    // Create a WebKit web view
    WebKitWebView *web_view = WEBKIT_WEB_VIEW(webkit_web_view_new());


    // Load a webpage
    gchar *html="<html><body>Hello embedded from framework now with slimmer API</body></html>";
//    webkit_web_view_load_html (web_view, html , "file:///hello.html" );
    webkit_web_view_load_uri(web_view, "myapp:///hello.html");

    // Add the web view to the window
    gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(web_view));

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}

@end
