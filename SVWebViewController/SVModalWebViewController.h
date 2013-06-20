//
//  SVModalWebViewController.h
//
//  Created by Oliver Letterer on 13.08.11.
//  Copyright 2011 Home. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import <UIKit/UIKit.h>

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

#pragma mark Set a given address in the address bar and load in the WebView.
- (void)setAndLoadAddress:(NSURLRequest *)request;

- (void)retrySimpleAuthentication;

#pragma mark Update the title in the nav bar.
- (void)updateTitle:(UIWebView *)webView;
#pragma mark Update the address in the nav bar.
- (void)updateAddress:(NSURL *)sourceURL;

@property (nonatomic, strong) UIColor *barsTintColor;
@property (nonatomic, readwrite) SVWebViewControllerAvailableActions availableActions;

@property (nonatomic, readonly, strong) SVWebSettings *settings;
@property (nonatomic, readonly, strong) SVWebViewController *webViewController;

@end
