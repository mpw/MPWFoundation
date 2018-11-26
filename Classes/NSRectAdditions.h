/* NSRectAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

typedef struct
{
    NSPoint ll;
    NSPoint ur;
} PSRect;

PSRect NSRect2PSRect( NSRect r1 );
NSRect PSRect2NSRect( PSRect r1 );
NSString *PSRect2NSString( PSRect r1 );
PSRect PaperType2PSRect( NSString *paperType );

