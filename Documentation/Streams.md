
Object Streams
==============


Unix Pipes and Filters meets dynamic OO.

Each filter responds to `-(void)writeObject:` and sends output to its `target`, also using `-(void)writeObject:`.



### Compostionality

Since the interface is simple and symmetric, you can compose filters in any way you please, very much like Unix filters.


### Synchrony and Asynchrony

By default, filters are synchronous, meaning the source filter calls its target filter before returning to its caller.  This is both simple and very efficient.

However, the model does not mandate this, and there are some filters that work asynchronously, for example the `MPWURLFetcher` or transfer control to another thread.


### Double Dispatch

Filters are actually polymorphic, that is they can respond differently to different objects.  Not all filters do this, some have the same behavior for every object.

However, some filters send a message to the object that it should write itself to the specific filter type.  For example the `MPWFlattenStream` sends `flattenOnto:` to the object in question, with itself as the argument.

### Unix I/O

`MPWByteStream` can serialize to bytes, also having `stdio`-like features like `-printf:`.  Howevever, unlike other mechanisms, it can either target Unix I/O directly, go to bytes in memory of even an `NSMutableString`.

There is also support for using a file descriptor as a data-source, for example for socket or pipe communication, and on macOS you can also easily shell out to external commands.

