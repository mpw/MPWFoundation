# MPWTableView (UIKit) example

`MPWTableView` is a `UICollectionView` subclass, so it can be used as a view
controller's root view or constrained like any other UIKit view.  It presents an
`MPWTable`: one collection-view item per row, one editor/value view per
`MPWObjectColumn`.  The concrete controls are chosen by
`+[MPWUIKitUIGenerator defaultTypes2UIMapper]` from each column's type, values are
read through `[column objectAtIndex:]` and written back through
`[column replaceObjectAtIndex:withObject:]`.

```objc
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundationUIKit/MPWFoundationUIKit.h>

- (void)loadView
{
    NSMutableArray *people = [[self.people mutableCopy] autorelease];
    MPWObjectArrayTable *table = [MPWObjectArrayTable tableWithObjects:people];

    MPWTableView *tableView = [[[MPWTableView alloc]
                               initWithFrame:CGRectZero] autorelease];
    [tableView setTable:table];

    // Optional: keep collection selection and an MPWArrayCursor in sync,
    // in both directions and without feedback loops.
    tableView.cursor = [[[MPWArrayCursor alloc]
                         initWithArray:table.objects] autorelease];

    self.view = tableView;
}
```

* The header row shows the capitalised column keys, matching the AppKit table.
* Editable columns produce interactive controls; edits write back through the
  column.  Non-editable columns are presented read-only.
* Long-press and drag a row to reorder it; the move is applied to the underlying
  table in the same order as the visual move.
* `-modelDidChange:` (the `ModelDidChange` protocol) reloads the collection.
```
