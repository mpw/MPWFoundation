
Stores and References
=============



In-Process REST
---------------


Stores
------

The basic storage protocol implements the following fundamental REST verbs: GET, PUT, DELETE.  In addition, Stores can convert a `String` to a `Reference`.

```
@protocol MPWStorage

-objectForReference:(id <MPWReferencing>)aReference;
-(void)setObject:theObject forReference:(id <MPWReferencing>)aReference;
-(void)deleteObjectForReference:(id <MPWReferencing>)aReference;

-(id <MPWReferencing>)referenceForPath:(NSString*)path;

@end

```

### Basic Stores

Basic stores work a lot like dictionaries: they store and retrieve objects, just that they take references instead of keys. 

In order to stay minimal, MPWFoundation only comes with two basic stores: `MPWDictStore` stores objects in a dictionary, `MPWDiskStore` stores (already serialized) objects on disk.

Other stores that have been implemented (mostly in Objective-Smalltalk) include the following:

- SQLite
- defaults (`NSDefaultsManager`)
- Unix environment
- http- and https-based stores
- Scripting Bridge to talk to other applications' data
- Apple WindowServer
- X11
- bundle

You can also easily expose any store as an HTTP server or a FUSE mountable filesystem, but again these are outside the scope of MPWFoundation.



### Storage Combinators



#### Mapping

The most simple combinator is `MPWMappingStore`, which takes a `source` store and transforms data and/or references.

In order to use it, you create a subclass and override one of its methods.  Values need to be transformed differently depending on whether we are storing or retrieving values (hopefully these transformations are inverses of each other):

```
-mapRetrievedObject:anObject forReference:(id <MPWReferencing>)aReference;
-mapObjectToStore:anObject forReference:(id <MPWReferencing>)aReference;
```

The first method transforms the object retrieved from the source, the second method transforms the object that will be stored to the source.

There is only a single method for mapping references, because the transformation is independent of the direction of value transfer.

```
-(id <MPWReferencing>)mapReference:(id <MPWReferencing>)aReference;
```

#### Caching

A cache has two sources, the base and the cache.  When retrieving an object, it first tries to retrieve it from the cache.  If it finds it there, it returns it.

If it doesn't find the object in the cache, it then checks the base.  If it finds it in the base, it returns the object and also puts it in the cache.



#### Logging/Notification

A logging store logs every access (configurable) to a stream.




References
----------

References are very similar to URIs.  They support conversion to and from strings and URLs as well as component access for the convenience of Stores and computation on references.

```
@protocol MPWReferencing

@property (readonly) NSArray<NSString*> *pathComponents;
@property (readonly) NSArray<NSString*> *relativePathComponents;
@property (nonatomic, strong) NSString *schemeName;
@property (readonly) NSString *path;

-(instancetype)referenceByAppendingReference:(id<MPWReferencing>)other;

@end
```

Built-in references include the `MPWGenericReference`, which consists of an array of path components (strings) and `MPWURLReference`, which wraps an `NSURL`.

Clients typically define their own reference types that are specific to their object model.

