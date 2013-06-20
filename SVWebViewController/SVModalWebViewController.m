//
//  SVModalWebViewController.m
//
//  Created by Oliver Letterer on 13.08.11.
//  Copyright 2011 Home. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (NO==self.settings.addressBar.isHidden) {
        
        if (self.settings.addressBar.isScrolling) {
            [self setNavigationBarHidden:YES];
            
        } else {
            self.settings.addressBar.tintColor = self.barsTintColor;
            self.webViewController.addressBar = [[SVAddressBar alloc] initWithSettings:self.settings.addressBar];
            [self addChildViewController:self.webViewController.addressBar];
            [self.navigationBar addSubview:self.webViewController.addressBar.view];
            [self.webViewController.addressBar didMoveToParentViewController:self];
        }
    }
}

- (void)setAndLoadAddress:(NSURLRequest *)request
{
    [self updateAddress:request.URL];
    [self loadAddress:self event:nil];
}

- (void)retrySimpleAuthentication
{
    [self loadAddress:self event:nil];
}

- (void)loadAddress:(id)sender event:(UIEvent *)event
{
    NSMutableURLRequest* request;
    NSString *urlString = self.webViewController.addressBar.addressField.text;
    if (NSNotFound!=[urlString rangeOfString:@" "].location
        || NSNotFound==[urlString rangeOfString:@"."].location) {
        urlString = [self.webViewController getSearchQuery:urlString];
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
    } else {
        if (0 ==[urlString rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            
        } else if (0 ==[urlString rangeOfString:@"https://" options:NSCaseInsensitiveSearch].location) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            
        } else {
            if (self.settings.isUseHTTPSWhenPossible) {
                urlString = [@"https://" stringByAppendingString:urlString];
                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                request = [self.webViewController requestForAttemptingHTTPS:request];
                
            } else {
                urlString = [@"http://" stringByAppendingString:urlString];
                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            }
        }
    }
    
    [self updateAddress:request.URL];
    
    [self.webViewController loadRequest:request];
}

- (void)updateTitle:(UIWebView *)webView
{
    NSString* pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.webViewController.addressBar.pageTitle.text = pageTitle;
}

- (void)updateAddress:(NSURL *)sourceURL
{
    if (NO==[self.webViewController isAddressAJavascriptEvaluation:sourceURL]) {
        if (NO==self.webViewController.addressBar.addressField.editing) {
            self.webViewController.addressBar.addressField.text = sourceURL.absoluteString;
        }
    }
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
