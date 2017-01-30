/* NSRectAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

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

