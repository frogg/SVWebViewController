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

@interface SVModalWebViewController : UINavigationController

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL withView:(UIWebView *)view;

#pragma mark Set a given address in the address bar and load in the WebView.
- (void)setAndLoadAddress:(NSURLRequest *)request;

#pragma mark Update the title in the nav bar.
- (void)updateTitle:(UIWebView *)webView;
#pragma mark Update the address in the nav bar.
- (void)updateAddress:(NSURL *)sourceURL;

@property (nonatomic, strong) UIColor *barsTintColor;
@property (nonatomic, readwrite) SVWebViewControllerAvailableActions availableActions;

@property BOOL isApplyFullscreenExitViewBoundsSizeFix;

@property (nonatomic, strong) SVWebSettings *settings;

@end
