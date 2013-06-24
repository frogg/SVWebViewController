//
//  SVModalWebViewController.h
//
//  Created by Ben Pettit on 24/06/2013
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController


enum {
    SVWebViewControllerAvailableActionsNone             = 0,
    SVWebViewControllerAvailableActionsOpenInSafari     = 1 << 0,
    SVWebViewControllerAvailableActionsMailLink         = 1 << 1,
    SVWebViewControllerAvailableActionsCopyLink         = 1 << 2
};

typedef NSUInteger SVWebViewControllerAvailableActions;


@class SVWebViewController, SVWebSettings;

@interface SVModalWebViewController : UINavigationController <UIViewControllerRestoration>

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL withSettings:(SVWebSettings *)settings;

- (void)retrySimpleAuthentication;

@property (nonatomic, strong) UIColor *barsTintColor;
@property (nonatomic, readwrite) SVWebViewControllerAvailableActions availableActions;

@property (nonatomic, readonly, strong) SVWebSettings *settings;
@property (nonatomic, readonly, strong) SVWebViewController *webViewController;

@end
