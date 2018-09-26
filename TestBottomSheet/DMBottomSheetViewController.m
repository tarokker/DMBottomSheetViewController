//
//  DMBottomSheetViewController.m
//  DMBottomSheetViewController
//
//  Created by Daniele Maiorana on 30/05/17.
//  Copyright © 2017 Daniele Maiorana. All rights reserved.
//

#import "DMBottomSheetViewController.h"

#define IS_IPHONE               (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define SCREEN_WIDTH            ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT           ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH       (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_IPHONE_X             (IS_IPHONE && SCREEN_MAX_LENGTH == 812.0)
#define IS_IPHONE_XMAX                                      (IS_IPHONE && SCREEN_MAX_LENGTH == 896.0)
#define IS_IPHONE_X_SERIES                                  (IS_IPHONE_XMAX || IS_IPHONE_X)


#define kBottomSpaceForIphoneX 36
#define kTopSpaceForIphoneX 24

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
    UIView *navView, *shadowNavView;
    UIView *holderRootView;
    UILabel *lblTitle;
    BOOL isFullOpened;
}

- (void)_fixPositionYIfTooHigh;
- (void)_recalcNavbarColors:(BOOL)animated;
- (void)_animateScrollToTopWithAddedAnimations:(void(^)())addedAnimations;
- (void)_animateScrollToHalfWithAddedAnimations:(void(^)())addedAnimations;

@end

@implementation DMBottomSheetViewController

- (instancetype)initWithRootViewController:(UIViewController *)rootctl
{
    if ( self = [super init] )
    {
        // config
        _tapOnBackViewClose = YES;
        isFullOpened = NO;
        CGFloat screenSize = MAX( [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height );
        _minimizedHeight = screenSize / 2.5;
        
        // view background trasparente
        backView = [[UIView alloc] initWithFrame:self.view.bounds];
        backView.backgroundColor = [UIColor blackColor];
        backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self setBackViewColorAlpha:0.8];
        [self.view addSubview:backView];
        
        // creiamo root holder view
        CGFloat bottom = IS_IPHONE_X_SERIES ? kBottomSpaceForIphoneX : 0;
        rootController = rootctl;
        holderRootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rootController.view.frame.size.width, rootController.view.frame.size.height + bottom)];
        holderRootView.backgroundColor = UIColor.whiteColor;
        [self.view addSubview:holderRootView];
        
        // aggiunge root controller e view root controller
        rootController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [holderRootView addSubview:rootController.view];
        [self addChildViewController:rootController];
        
        // navbar
        CGFloat top = IS_IPHONE_X_SERIES ? kTopSpaceForIphoneX : 0;
        navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64.0 + top)];
        navView.backgroundColor = [UIColor clearColor];
        navView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnClose addTarget:self action:@selector(didTapOnX:) forControlEvents:UIControlEventTouchUpInside];
        [btnClose setImage:[UIImage imageNamed:@"dmbs_gray_x"] forState:UIControlStateNormal];
        [btnClose setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin];
        [btnClose setFrame:CGRectMake(5, 26 + top, 38, 30)];
        lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, btnClose.frame.origin.y, navView.frame.size.width, btnClose.frame.size.height)];
        lblTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
        lblTitle.backgroundColor = [UIColor clearColor];
        lblTitle.textAlignment = NSTextAlignmentCenter;
        [lblTitle setAttributedText:[[NSAttributedString alloc] initWithString:(rootController.title?rootController.title:@"") attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName: self.titleFont}]];
        shadowNavView = [[UIView alloc] initWithFrame:CGRectMake(0, navView.frame.size.height - 1.0, navView.frame.size.width, 1.0)];
        [shadowNavView setBackgroundColor:[UIColor clearColor]];
        shadowNavView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        [navView addSubview:shadowNavView];
        [navView addSubview:lblTitle];
        [navView addSubview:btnClose];
        [self.view addSubview:navView];
        
        // tap su background per chiudere
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnBackgroundView:)];
        [backView addGestureRecognizer:tap];

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

- (void)setBackViewColorAlpha:(CGFloat)backViewColorAlpha
{
    _backViewColorAlpha = backViewColorAlpha;
    if ( backView )
    {
        backView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:_backViewColorAlpha];
    }
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
        holderRootView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, holderRootView.frame.size.height);
        backView.alpha = 0.0;
        navView.alpha = 0.0;
        shadowNavView.alpha = 0.0;
        
        // blocco animazione
        void(^animationOpeningBlock)() = ^()
        {
            backView.alpha = 1.0;
            navView.alpha = 1.0;
            shadowNavView.alpha = 1.0;
        };

        // anima apertura
        if ( _openAlreadyFull )
        {
            [self _animateScrollToTopWithAddedAnimations:^{
                animationOpeningBlock();
            }];
        }
        else
        {
            [self _animateScrollToHalfWithAddedAnimations:^{
                animationOpeningBlock();
            }];
        }
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
        if ( _self.didCloseBlock )
        {
            _self.didCloseBlock(_self);
        }
    };
    
    if ( _self.willCloseBlock )
    {
        _self.willCloseBlock(_self, animated);
    }

    if ( animated )
    {
        [UIView animateWithDuration:0.2 animations:^{
            holderRootView.frame = CGRectMake(holderRootView.frame.origin.x, self.view.frame.size.height, holderRootView.frame.size.width, holderRootView.frame.size.height);
            backView.alpha = 0.0;
            navView.alpha = 0.0;
            shadowNavView.alpha = 0.0;
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
    if ( CGRectGetMaxY(holderRootView.frame) < self.view.frame.size.height )
    {
        holderRootView.frame = CGRectMake(holderRootView.frame.origin.x, self.view.frame.size.height - holderRootView.frame.size.height, holderRootView.frame.size.width, holderRootView.frame.size.height);
    }
}

- (void)_recalcNavbarColors:(BOOL)animated
{
    if ( holderRootView.frame.origin.y <= CGRectGetMaxY(navView.frame) )
    {
        if ( navView.tag == 0 )
        {
            [lblTitle setAttributedText:[[NSAttributedString alloc] initWithString:(rootController.title?rootController.title:@"") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0], NSFontAttributeName: self.titleFont}]];
            [shadowNavView setBackgroundColor:[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:200.0/255.0]];
            if ( animated )
            {
                [UIView animateWithDuration:0.1 animations:^{
                    [navView setBackgroundColor:[UIColor whiteColor]];
                }];
            }
            else
            {
                [navView setBackgroundColor:[UIColor whiteColor]];
            }
            navView.tag = 1;
        }
    }
    else
    {
        if ( navView.tag == 1 )
        {
            [lblTitle setAttributedText:[[NSAttributedString alloc] initWithString:(rootController.title?rootController.title:@"") attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName: self.titleFont}]];
            [shadowNavView setBackgroundColor:[UIColor clearColor]];
            [navView setBackgroundColor:[UIColor clearColor]];
            navView.tag = 0;
        }
    }
}

// aggancia in alto o fino a dove puoi
- (void)_animateScrollToTopWithAddedAnimations:(void(^)())addedAnimations
{
    [UIView animateWithDuration:0.2 animations:^{
        if ( addedAnimations )
        {
            addedAnimations();
        }
        holderRootView.frame = CGRectMake(holderRootView.frame.origin.x, CGRectGetMaxY(navView.frame), holderRootView.frame.size.width, holderRootView.frame.size.height);
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
        holderRootView.frame = CGRectMake(0, self.view.frame.size.height - MIN(_minimizedHeight, holderRootView.frame.size.height), self.view.frame.size.width,holderRootView.frame.size.height);
        [self _fixPositionYIfTooHigh];
        [self _recalcNavbarColors:NO];
    }];
}

# pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:navView])
    {
        return NO;
    }
    return YES;
}

- (void)didSwipeGestureUp
{
    // ignora swipe up se la view e' comunque piu' del _minimizedHeight
    if ( holderRootView.frame.size.height < _minimizedHeight )
    {
        return;
    }
    
    // se abbiamo fatto swipe up e siamo half opened, apri full
    if ( !isFullOpened )
    {
        // aggancia in alto o fino a dove puoi
        [self _animateScrollToTopWithAddedAnimations:nil];
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
    
    CGPoint translatedPoint = [pan translationInView:holderRootView.superview];
    
    if ( pan.state == UIGestureRecognizerStateBegan )
    {
    }
    else if ( pan.state == UIGestureRecognizerStateChanged )
    {
        // transla la view
        translatedPoint = CGPointMake(holderRootView.center.x, holderRootView.center.y+translatedPoint.y);
        [holderRootView setCenter:translatedPoint];
        [pan setTranslation:CGPointZero inView:holderRootView];
        
        // riposiziona la view se e' troppo in alto
        [self _fixPositionYIfTooHigh];
        
        // ricalcola colori navibar, a seconda di dov'e' la view
        [self _recalcNavbarColors:YES];
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        // intercetta swipes o panning
        CGPoint vel = [pan velocityInView:holderRootView.superview];
        
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
            if ( self.view.frame.size.height - holderRootView.frame.origin.y < MIN(_minimizedHeight, holderRootView.frame.size.height) / 2.0)
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
                    if ( self.view.frame.size.height - holderRootView.frame.origin.y < _minimizedHeight )
                    {
                        isFullOpened = NO;
                    }
                    else
                    {
                        if ( holderRootView.frame.origin.y > CGRectGetMaxY(navView.frame) )
                        {
                            // aggancia in alto o fino a dove puoi
                            [self _animateScrollToTopWithAddedAnimations:nil];
                        }
                    }
                }
                
                // se non eravamo full opened, rimetti a meta se siamo sotto la meta
                // altrimenti metti fullopened se non lo siamo gia'
                if ( !isFullOpened )
                {
                    if ( self.view.frame.size.height - holderRootView.frame.origin.y < _minimizedHeight )
                    {
                        // anima l'apertura a meta'
                        [self _animateScrollToHalfWithAddedAnimations:nil];
                    }
                    else
                    {
                        if ( holderRootView.frame.origin.y > CGRectGetMaxY(navView.frame) )
                        {
                            [self didSwipeGestureUp];
                        }
                    }
                }
            }
        }
    }
}

- (void)didTapOnBackgroundView:(UITapGestureRecognizer *)gesture
{
    if ( _tapOnBackViewClose )
    {
        [self close:YES withCompletion:nil];
    }
}

@end
