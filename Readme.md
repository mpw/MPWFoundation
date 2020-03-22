
MPWFoundation
=============

Marcel Weiher,
metaobject GmbH.
http://www.metaobject.com


MPWFoundation provides a number of technologies to Cocoa, Cocoa Touch
and Objective-C development in general.

 - Higher Order Messaging (HOM)
 - Point and Rectangle objects
 - Efficient numbers and number arrays
 - Resource-loading conveniences for NSBundle

Storage Combinators
------

Implementation of in-process REST.

[Stores Documentation](Documentation/Stores.md) 


Object Filters
--------------

Unix pipes and filters meets dynamic messaging.

[Filter Documentation](Documentation/Streams.md) 


Higher Order Messaging
----------------------

Messages that can take messages as an argument.

An example, a common delegate pattern that checks if the delegate responds to the message we want to send:

```
if ( [self.delegate respondsToSelector:@selector(windowWillClose:)] ) {
    [self.delegate windowWillClose:self];
}
```

can instead be expressed as

```
[[self.delegate ifResponds] windowDidClose:self];
```

Note that the first example, apart from being verbose, also has a bug that gets hidden by the verbosity.

[HOM Documentation](Documentation/HOM.md) 



Object Cache
------------

Reuse temporary objects, quickly.


Serialization
-------------

[Serialization Documentation](Documentation/Serialization.md) 


- Fast and memory-efficient implementation of binary proprerty lists
- JSON generator
- XML parser and generator
- Fast CSV parser
- Macro-based conveniences for `NSArchiver` and `NSKeyedArchiver`


Some more stuff


Collections
-----------

- fast real and integer arrays
- fast (small) dictionary with C-String keys





License
========

MPWFoundation is Copyright 1998-2018 by Marcel Weiher.  
Dual licensed under BSD 3 part and LGPL.
