
Notifcation Protocols
=====================


Notification Protocols let you declare `NSNotification` statically in yor class definition and take care of much of the subsequent mechanics automatically:

```
@interface NotifiedView:NSView <ModelDidChange>

@end
```

This declares that `NotifiedView` will be listening too the `ModelDidChange` notification.  The protocol defines the message that will be sent to `NotifiedView`, in this case the `-modelDidChange:` message:

```
@protocol ModelDidChange <MPWNotificationProtocol>

-(void)modelDidChange:(NSNotifiction*)notification;

@end
```


With that in-place, all you have to do is send `[self installProtocolNotifications]` somewhere in your initializer. 

```
@interface NotifiedView:NSView <ModelDidChange>

@end
```


### Details

In order to make this work, the object declaring conformance needs to send the -