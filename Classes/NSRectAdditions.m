/* NSRectAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


//#import "MPWFoundation.h"
#import "MPWRect.h"
#import "NSRectAdditions.h"

PSRect NSRect2PSRect( NSRect r1 )
{
    PSRect result;
    result.ll = r1.origin;
    result.ur = r1.origin;
    result.ur.x += r1.size.width;
    result.ur.y += r1.size.height;
    return result;
}
NSRect PSRect2NSRect( PSRect r1 )
{
    NSRect result;
    result.origin =r1.ll;
    result.size.width=r1.ur.x-r1.ll.x;
    result.size.height=r1.ur.y-r1.ll.y;
    return result;
}

NSString *PSRect2NSString( PSRect r1 )
{
    return [NSString stringWithFormat:@"[ %g %g %g %g ]",
        r1.ll.x,r1.ll.y,r1.ur.x,r1.ur.y];
}

PSRect PaperType2PSRect( NSString *paperType )
{
    PSRect result={
    { 0,0},{595,742}
    };
    return result;
}

