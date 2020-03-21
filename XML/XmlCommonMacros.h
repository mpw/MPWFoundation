
#ifndef XMLCHAR
#define	XMLCHAR( x )	(x)
#endif

#ifndef NATIVECHAR
#define	NATIVECHAR( x )	(x)
#endif

#ifndef ISOPENTAG
#define ISOPENTAG(x)	((x)==XMLCHAR('<'))
#endif
#ifndef ISCLOSETAG
#define ISCLOSETAG(x)	((x)==XMLCHAR('>'))
#endif
#ifndef ISNAMESPACEDELIMITER
#define ISNAMESPACEDELIMITER(x)    ((x)==XMLCHAR(':'))
#endif

#ifndef ISAMPERSAND
#define ISAMPERSAND(x)	((x)==XMLCHAR('&'))
#endif
#ifndef ISSEMICOLON
#define ISSEMICOLON(x)	((x)==XMLCHAR(';'))
#endif
#ifndef ISHYPHEN
#define ISHYPHEN(x)		((x)==XMLCHAR('-'))
#endif
#ifndef ISSINGLEQUOTE
#define ISSINGLEQUOTE(x)		((x)==XMLCHAR('\''))
#endif
#ifndef ISDOUBLEQUOTE
#define ISDOUBLEQUOTE(x)		((x)==XMLCHAR('"'))
#endif
#ifndef ISRIGHTSQUAREBRACKET
#define ISRIGHTSQUAREBRACKET(x)	((x)==XMLCHAR(']'))
#endif
#ifndef ISSLASH
#define ISSLASH(x)	((x)==XMLCHAR('/'))
#endif

#ifndef	EMPTYSTRING
#define	EMPTYSTRING	""
#endif
