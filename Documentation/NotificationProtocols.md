
Notifcation Protocols
=====================


Notification Protocols are a convenience for making certain idiomatic `NSNotification` interactions dramatically more convenient.

You can declare a Notification Protocol as a protocol that conform to `MPWNotificationProtocol`:

```
@protocol ModelDidChange <MPWNotificationProtocol>

-(void)modelDidChange:(NSNotifiction*)notification;

@end
```

Once you have the protocol, you can declare that a class conforms to it:

```
@interface NotifiedView:NSView <ModelDidChange>

@end
```

With that in-place, all you have to do is send `[self installProtocolNotifications]` somewhere in your initializer.  

You can then send a notification based on the name of the protocol, in this case `ModelDidChange` and it will be received by all the object that declared conformance to the protocol.

There's even a handy Macro to do that:

```
PROTOCOL_NOTIFY(ModelDidChange,changedUri);
```

