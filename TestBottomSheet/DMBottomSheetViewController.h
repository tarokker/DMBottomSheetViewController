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

// config
@property(nonatomic, assign) BOOL openAlreadyFull;
@property(nonatomic, assign) CGFloat minimizedHeight;
@property(nonatomic, copy) UIFont *titleFont;
@property(nonatomic, assign) BOOL tapOnBackViewClose;
@property(nonatomic, assign) CGFloat backViewColorAlpha;

// blocchi
@property (nonatomic, copy) void (^willCloseBlock)(DMBottomSheetViewController *source, BOOL animated);
@property (nonatomic, copy) void (^didCloseBlock)(DMBottomSheetViewController *source);

- (instancetype)initWithRootViewController:(UIViewController *)rootctl withCustomCloseButton:(UIButton *)customCloseButton;
- (instancetype)initWithRootViewController:(UIViewController *)rootctl;
- (void)presentInParentController:(UIViewController *)parentctl;
- (void)close:(BOOL)animated withCompletion:(void(^)())completion;

@end
