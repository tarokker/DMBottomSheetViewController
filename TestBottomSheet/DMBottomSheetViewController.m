//
//  DMBottomSheetViewController.m
//  DMBottomSheetViewController
//
//  Created by Daniele Maiorana on 30/05/17.
//  Copyright © 2017 Daniele Maiorana. All rights reserved.
//

#import "DMBottomSheetViewController.h"

@implementation UIViewController (dismissDMBottomSheetViewController)

- (DMBottomSheetViewController *)dmBottomSheetViewController
{
    if ( [self.parentViewController isKindOfClass:[UINavigationController class]] )
    {
        UINavigationController *navCtl = (UINavigationController *)self.parentViewController;
        
        if ( [navCtl.parentViewController isKindOfClass:[DMBottomSheetViewController class]] )
        {
            return (DMBottomSheetViewController *)navCtl.parentViewController;
        }
    }
    else if ( [self.parentViewController isKindOfClass:[DMBottomSheetViewController class]] )
    {
        return (DMBottomSheetViewController *)self.parentViewController;
    }
    return nil;
}

@end

@interface DMBottomSheetViewController ()
{
@private
    __weak UIViewController *rootController;
    UIView *backView;
    UINavigationBar *navBar;
    BOOL isFullOpened;
}

- (void)_fixPositionYIfTooHigh;
- (void)_recalcNavbarColors:(BOOL)animated;
- (void)_animateScrollToTop;
- (void)_animateScrollToHalfWithAddedAnimations:(void(^)())addedAnimations;

@end

@implementation DMBottomSheetViewController

- (instancetype)initWithRootViewController:(UIViewController *)rootctl
{
    if ( self = [super init] )
    {
        // config
        isFullOpened = NO;
        CGFloat screenSize = MAX( [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height );
        _minimizedHeight = screenSize / 2.5;
        
        // view background trasparente
        backView = [[UIView alloc] initWithFrame:self.view.bounds];
        backView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:backView];
        
        // aggiunge root controller e view root controller
        rootController = rootctl;
        rootController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:rootController.view];
        [self addChildViewController:rootController];
        
        // navbar
        navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64.0)];
        navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        [navItem setTitle:rootController.title];
        [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName: self.titleFont}];
        [navBar setTintColor:[UIColor colorWithRed:0.600 green:0.600 blue:0.600 alpha:1.00]];
        [navBar setBackgroundColor:nil];
        [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [navBar setShadowImage:[UIImage new]];
        [navItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dmbs_gray_x"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapOnX:)]];
        [navBar setItems:@[navItem]];
        [self.view addSubview:navBar];
        
        // aggiunge gesture sulla view
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanGesture:)];
        pan.delegate = self;
        [self.view addGestureRecognizer:pan];
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // Non supportiamo la rotazione momentaneamente, chiudiamo il controller
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self close:NO withCompletion:nil];
}

- (void)didTapOnX:(id)sender
{
    [self close:YES withCompletion:nil];
}

# pragma mark - Proprieta

- (UIFont *)titleFont
{
    if ( !_titleFont )
    {
        UIFont *mTitleFont = [UIFont fontWithName:@"SFUIText-Medium" size:17.0];
        if ( !mTitleFont )
        {
            mTitleFont = [UIFont boldSystemFontOfSize:17.0];
        }
        _titleFont = [mTitleFont copy];
    }
    return _titleFont;
}

# pragma mark - Apertura / Chiusura

- (void)presentInParentController:(UIViewController *)parentctl
{
    // gia' aggiunto ad un altro controller
    if ( [self parentViewController] )
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // aggiunge al parent controller
        isFullOpened = NO;
        [self.view setFrame:parentctl.view.bounds];
        [parentctl.view addSubview:self.view];
        [parentctl addChildViewController:self];
        
        // riposiziona backview
        self.view.frame = parentctl.view.bounds;
        rootController.view.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, rootController.view.frame.size.height);
        backView.alpha = 0.0;
        navBar.alpha = 0.0;
        
        // anima apertura
        [self _animateScrollToHalfWithAddedAnimations:^{
            backView.alpha = 1.0;
            navBar.alpha = 1.0;
        }];
    });
}

- (void)close:(BOOL)animated withCompletion:(void(^)())completion
{
    __weak DMBottomSheetViewController *_self = self;
    
    void(^closeBlock)() = ^()
    {
        [rootController removeFromParentViewController];
        [_self.view removeFromSuperview];
        [_self removeFromParentViewController];
        if ( completion )
        {
            completion();
        }
    };
    
    if ( animated )
    {
        [UIView animateWithDuration:0.2 animations:^{
            rootController.view.frame = CGRectMake(rootController.view.frame.origin.x, self.view.frame.size.height, rootController.view.frame.size.width, rootController.view.frame.size.height);
            backView.alpha = 0.0;
            navBar.alpha = 0.0;
        } completion:^(BOOL finished) {
            closeBlock();
        }];
    }
    else
    {
        closeBlock();
    }
}

# pragma mark - Riposizionamenti e animazione

// riposiziona la view se e' troppo in alto
- (void)_fixPositionYIfTooHigh
{
    if ( CGRectGetMaxY(rootController.view.frame) < self.view.frame.size.height )
    {
        rootController.view.frame = CGRectMake(rootController.view.frame.origin.x, self.view.frame.size.height - rootController.view.frame.size.height, rootController.view.frame.size.width, rootController.view.frame.size.height);
    }
}

- (void)_recalcNavbarColors:(BOOL)animated
{
    if ( rootController.view.frame.origin.y <= CGRectGetMaxY(navBar.frame) )
    {
        if ( navBar.tag == 0 )
        {
            [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0], NSFontAttributeName: self.titleFont}];
            [navBar setShadowImage:nil];
            if ( animated )
            {
                [UIView animateWithDuration:0.1 animations:^{
                    [navBar setBackgroundColor:[UIColor whiteColor]];
                }];
            }
            else
            {
                [navBar setBackgroundColor:[UIColor whiteColor]];
            }
            navBar.tag = 1;
        }
    }
    else
    {
        if ( navBar.tag == 1 )
        {
            [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName: self.titleFont}];
            [navBar setBackgroundColor:nil];
            [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [navBar setShadowImage:[UIImage new]];
            navBar.tag = 0;
        }
    }
}

// aggancia in alto o fino a dove puoi
- (void)_animateScrollToTop
{
    [UIView animateWithDuration:0.2 animations:^{
        rootController.view.frame = CGRectMake(rootController.view.frame.origin.x, CGRectGetMaxY(navBar.frame), rootController.view.frame.size.width, rootController.view.frame.size.height);
        [self _fixPositionYIfTooHigh];
        [self _recalcNavbarColors:NO];
    }];
}

// anima l'apertura a meta'
- (void)_animateScrollToHalfWithAddedAnimations:(void(^)())addedAnimations
{
    [UIView animateWithDuration:0.2 animations:^{
        if ( addedAnimations )
        {
            addedAnimations();
        }
        rootController.view.frame = CGRectMake(0, self.view.frame.size.height - MIN(_minimizedHeight, rootController.view.frame.size.height), self.view.frame.size.width,rootController.view.frame.size.height);
        [self _fixPositionYIfTooHigh];
        [self _recalcNavbarColors:NO];
    }];
}

# pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:navBar])
    {
        return NO;
    }
    return YES;
}

- (void)didSwipeGestureUp
{
    // ignora swipe up se la view e' comunque piu' del _minimizedHeight
    if ( rootController.view.frame.size.height < _minimizedHeight )
    {
        return;
    }
    
    // se abbiamo fatto swipe up e siamo half opened, apri full
    if ( !isFullOpened )
    {
        // aggancia in alto o fino a dove puoi
        [self _animateScrollToTop];
        isFullOpened = YES;
    }
}

- (void)didSwipeGestureDown
{
    // swipe down: se era aperto a meta' chiudiamo, altrimenti apri a meta'
    if ( !isFullOpened )
    {
        [self close:YES withCompletion:nil];
    }
    else
    {
        [self _animateScrollToHalfWithAddedAnimations:nil];
        isFullOpened = NO;
    }
}

- (void)didPanGesture:(UIPanGestureRecognizer *)pan
{
    const CGFloat SWIPE_UP_THRESHOLD = 1000.0f;
    
    CGPoint translatedPoint = [pan translationInView:rootController.view.superview];
    
    if ( pan.state == UIGestureRecognizerStateBegan )
    {
    }
    else if ( pan.state == UIGestureRecognizerStateChanged )
    {
        // transla la view
        translatedPoint = CGPointMake(rootController.view.center.x, rootController.view.center.y+translatedPoint.y);
        [rootController.view setCenter:translatedPoint];
        [pan setTranslation:CGPointZero inView:rootController.view];
        
        // riposiziona la view se e' troppo in alto
        [self _fixPositionYIfTooHigh];
        
        // ricalcola colori navibar, a seconda di dov'e' la view
        [self _recalcNavbarColors:YES];
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        // intercetta swipes o panning
        CGPoint vel = [pan velocityInView:rootController.view.superview];
        
        if ( vel.y < -SWIPE_UP_THRESHOLD )
        {
            [self didSwipeGestureUp];
        }
        else if ( vel.y > SWIPE_UP_THRESHOLD )
        {
            [self didSwipeGestureDown];
        }
        else
        {
            // gestione pan
            // chiudi se siamo oltre il margine di chiusura
            if ( self.view.frame.size.height - rootController.view.frame.origin.y < MIN(_minimizedHeight, rootController.view.frame.size.height) / 2.0)
            {
                [self close:YES withCompletion:nil];
            }
            else
            {
                // non siamo oltre il margine di chiusura:
                // se eravamo full opened e abbiamo raggiunto al minimo, rimuovi full opened
                // altrimenti riposiziona al massimo se non lo siamo gia'
                if ( isFullOpened )
                {
                    if ( self.view.frame.size.height - rootController.view.frame.origin.y < _minimizedHeight )
                    {
                        isFullOpened = NO;
                    }
                    else
                    {
                        if ( rootController.view.frame.origin.y > CGRectGetMaxY(navBar.frame) )
                        {
                            // aggancia in alto o fino a dove puoi
                            [self _animateScrollToTop];
                        }
                    }
                }
                
                // se non eravamo full opened, rimetti a meta se siamo sotto la meta
                // altrimenti metti fullopened se non lo siamo gia'
                if ( !isFullOpened )
                {
                    if ( self.view.frame.size.height - rootController.view.frame.origin.y < _minimizedHeight )
                    {
                        // anima l'apertura a meta'
                        [self _animateScrollToHalfWithAddedAnimations:nil];
                    }
                    else
                    {
                        if ( rootController.view.frame.origin.y > CGRectGetMaxY(navBar.frame) )
                        {
                            [self didSwipeGestureUp];
                        }
                    }
                }
            }
        }
    }
}

@end
