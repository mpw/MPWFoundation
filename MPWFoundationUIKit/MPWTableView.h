//
//  MPWTableView.h
//  MPWFoundationUIKit
//
//  Created by Marcel Weiher on 26.06.26.
//

#import <UIKit/UIKit.h>
#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWTableView : UITableView <UITableViewDataSource,ModelDidChange,SelectionDidChange,UITableViewDelegate>
 
@end

NS_ASSUME_NONNULL_END
