//
//  DMBottomSheetViewController.h
//  DMBottomSheetViewController
//
//  Created by Daniele Maiorana on 30/05/17.
//  Copyright © 2017 Daniele Maiorana. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMBottomSheetViewController;

@interface UIViewController (dismissDMBottomSheetViewController)

- (DMBottomSheetViewController *)dmBottomSheetViewController;

@end

@interface DMBottomSheetViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic, assign) CGFloat minimizedHeight;
@property(nonatomic, copy) UIFont *titleFont;

- (instancetype)initWithRootViewController:(UIViewController *)rootctl;
- (void)presentInParentController:(UIViewController *)parentctl;
- (void)close:(BOOL)animated withCompletion:(void(^)())completion;

@end
