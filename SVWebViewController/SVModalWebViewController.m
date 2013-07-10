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


#pragma mark - Public methods

- (void)setAvailableActions:(SVWebViewControllerAvailableActions)newAvailableActions {
    self.webViewController.availableActions = newAvailableActions;
}

- (void)retrySimpleAuthentication
{
    [self.webViewController.addressBar loadAddress];
}


#pragma mark - View methods

- (void)loadView
{
    [super loadView];
    [self setNavigationBarHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    self.navigationBar.tintColor = self.barsTintColor;
    self.toolbar.tintColor = self.barsTintColor;
}

- (void)viewWillLayoutSubviews
{
    [self bugFixForBarButtonsBeingRemovedByActionSheet];
}


#pragma mark - Private methods

- (void)bugFixForBarButtonsBeingRemovedByActionSheet
{
    self.webViewController.toolbarItems=0;
    [self.webViewController updateToolbarItems:self.webViewController.isLoadingPage];
}


#pragma mark - UI State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    UIViewController *thisViewController=nil;
    
    if (1<identifierComponents.count) {
        NSString *parentViewControllerID = [identifierComponents objectAtIndex:identifierComponents.count-2];
        UIViewController *parentViewController = [coder decodeObjectForKey:parentViewControllerID];
        for (UIViewController *childViewController in parentViewController.childViewControllers) {
            if (childViewController.class==self.class) {
                thisViewController = childViewController;
            }
        }
        
    } else {
        SVWebSettings *settings = [coder decodeObjectForKey:NSStringFromClass(SVWebSettings.class)];
        
        thisViewController = [[SVModalWebViewController alloc] initWithURL:nil withSettings:settings];
    }
    
    return thisViewController;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    if (self.parentViewController) {
        [coder encodeObject:self.parentViewController forKey:NSStringFromClass(self.parentViewController.class)];
    }
    [coder encodeObject:self.settings forKey:NSStringFromClass(SVWebSettings.class)];
    
    [super encodeRestorableStateWithCoder:coder];
}

@end
