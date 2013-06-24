//
//  SVModalWebViewController.m
//
//  Created by Ben Pettit on 24/06/2013
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//
//  https://github.com/pellet/SVWebViewController

#import "SVModalWebViewController.h"
#import "SVWebViewController.h"
#import "SVWebSettings.h"
#import "SVModalWebNavigationBar.h"
#import "SVAddressBarSettings.h"
#import "SVAddressBar.h"


@interface SVWebViewController()
@property (strong) UIWebView *mainWebView;
@end

@interface SVModalWebViewController ()

@property (nonatomic, strong) SVWebViewController *webViewController;

@property (nonatomic, strong) SVWebSettings *settings;

@property (nonatomic, strong) UIView *statusBarOverlay;
@property (nonatomic, strong) UIColor *spacerColor;

@end


@implementation SVModalWebViewController

#pragma mark - Initialization

- (id)initWithAddress:(NSString*)urlString {
    self = [self initWithURL:[NSURL URLWithString:urlString]];
    return self;
}

- (id)initWithURL:(NSURL *)URL {
    self = [self initWithURL:URL withSettings:[SVWebSettings new]];
    return self;
}

- (id)initWithURL:(NSURL *)URL withSettings:(SVWebSettings *)settings {
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL withSettings:settings];
    self.settings = settings;
    self = [self initWebViewController:webViewController];
    
    return self;
}

- (id)initWebViewController:(SVWebViewController *)theWebViewController
{
    Class navBarClass=nil;
    if (UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM()) {
        navBarClass = SVModalWebNavigationBar.class;
    }
    
    self = [super initWithNavigationBarClass:navBarClass toolbarClass:nil];
    
    if (nil!=self) {
        [self pushViewController:theWebViewController animated:NO];
        
        self.webViewController = theWebViewController;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.restorationClass = self.class;
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    [self setNavigationBarHidden:YES];
}

- (void)retrySimpleAuthentication
{
    [self.webViewController.addressBar loadAddress];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    self.navigationBar.tintColor = self.barsTintColor;
    self.toolbar.tintColor = self.barsTintColor;
}

- (void)setAvailableActions:(SVWebViewControllerAvailableActions)newAvailableActions {
    self.webViewController.availableActions = newAvailableActions;
}

- (void)viewWillLayoutSubviews
{
    [self bugFixForBarButtonsBeingRemovedByActionSheet];
}

- (void)bugFixForBarButtonsBeingRemovedByActionSheet
{
    self.webViewController.toolbarItems=0;
    [self.webViewController updateToolbarItems:self.webViewController.isLoadingPage];
}


#pragma mark - UI State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    SVModalWebViewController *thisViewController=nil;
    
    SVWebSettings *settings = [coder decodeObjectForKey:NSStringFromClass(SVWebSettings.class)];
    
    thisViewController = [[SVModalWebViewController alloc] initWithURL:nil withSettings:settings];
    thisViewController.restorationIdentifier = identifierComponents.lastObject;
    thisViewController.restorationClass = self.class;
    
    return thisViewController;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.webViewController forKey:[SVModalWebViewController KEY_WEBVIEW_CONTROLLER]];
    
    [coder encodeObject:self.settings forKey:NSStringFromClass(SVWebSettings.class)];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.webViewController = [coder decodeObjectForKey:[SVModalWebViewController KEY_WEBVIEW_CONTROLLER]];
}

#pragma mark Key constants used by the coder.
+ (NSString *)KEY_WEBVIEW_CONTROLLER
{
    return @"KEY_WEBVIEW_CONTROLLER";
}

@end
