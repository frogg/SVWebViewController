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


@interface SVWebViewController()
@property (strong) UIWebView *mainWebView;
@end

@interface SVModalWebViewController ()

@property (nonatomic, strong) SVWebViewController *webViewController;

@property (nonatomic, strong) UILabel* pageTitle;
@property (nonatomic, strong) UITextField* addressField;
@property (nonatomic, strong) SVWebSettings *settings;

@property (nonatomic, strong) UIView *statusBarOverlay;
@property (nonatomic, strong) UIColor *spacerColor;
@property (nonatomic, strong) UIToolbar *addressToolbar;

@property (nonatomic, strong) UIView *container;

@end

static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 1.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;
static const CGFloat kNavBarHeight = kSpacer*4 + kLabelHeight + kAddressHeight;


static const CGFloat kAlphaStandard = 0.75;
static const NSInteger kStatusBarHeight = 20;


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
    self.toolbarSpacingAlpha = kAlphaStandard;
    if (self.settings.isScrollingAddressBar) {
        [self setNavigationBarHidden:YES];
    }
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

- (void)addScrollingAddressBar
{
    if (self.settings.isScrollingAddressBar) {
        [self addScrollingAddressBar:self.addressToolbar withScrollView:self.webViewController.mainWebView.scrollView];
    }
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)addScrollingAddressBar:(UIView *)addressBar withScrollView:(UIScrollView *)view
{
    static NSString * const WEB_BROWSER_CLASS_NAME = @"UIWebBrowserView";
    for (UIView *webSubView in view.subviews) {
        if ([WEB_BROWSER_CLASS_NAME isEqualToString:NSStringFromClass(webSubView.class)]) {
            
            CGRect containerFrame = self.container.frame;
            containerFrame.size.width = view.frame.size.width;
            self.container.frame = containerFrame;
            
            CGRect webViewColorFrame;
            webViewColorFrame.size.width = view.frame.size.width;
            webViewColorFrame.size.height = kStatusBarHeight;
            UIView *webViewColor = [[UIView alloc] initWithFrame:webViewColorFrame];
            webViewColor.backgroundColor = self.webViewController.mainWebView.backgroundColor;
            [self.container addSubview:webViewColor];
            
            CGRect spacingForStatusBar;
            spacingForStatusBar.size.height = kStatusBarHeight;
            spacingForStatusBar.size.width = view.frame.size.width;
            self.statusBarOverlay = [[UIToolbar alloc] initWithFrame:spacingForStatusBar];
            self.statusBarOverlay.alpha = self.toolbarSpacingAlpha;
            self.statusBarOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [self.webViewController.mainWebView addSubview:self.statusBarOverlay];
            
            CGRect addressBarFrame = addressBar.frame;
            addressBarFrame.origin.y = kStatusBarHeight;
            addressBarFrame.size.width = view.frame.size.width;
            addressBar.frame = addressBarFrame;
            
            [self.webViewController.mainWebView.scrollView addSubview:self.addressToolbar];
            
            CGRect webBrowserFrame = webSubView.frame;
            webBrowserFrame.origin.y = self.addressToolbar.frame.size.height+kStatusBarHeight; // Shift down
            webSubView.frame = webBrowserFrame;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.settings.isShowAddressBar) {
        CGRect containerFrame = self.view.bounds;
        containerFrame.size.height = kNavBarHeight+kStatusBarHeight;
        self.container = [[UIView alloc] initWithFrame:containerFrame];
        
        CGRect addressBarFrame = self.view.bounds;
        addressBarFrame.size.height = kNavBarHeight;
        addressBarFrame.origin.y = kStatusBarHeight;
        self.addressToolbar = [[UIToolbar alloc] initWithFrame:addressBarFrame];
        self.addressToolbar.alpha = kAlphaStandard;
        self.addressToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.pageTitle =  [self createTitleWithNavBar:self.addressToolbar];
        [self.addressToolbar addSubview:self.pageTitle];
        
        self.addressField = [self createAddressFieldWithToolBar:self.addressToolbar];
        [self.addressToolbar addSubview:self.addressField];
        
        [self.container addSubview:self.addressToolbar];
        
        [self.navigationBar addSubview:self.addressToolbar];
    }
}

- (UILabel *)createTitleWithNavBar:(UIToolbar *)toolBar
{
    CGRect labelFrame = CGRectMake(kMargin, kSpacer,
                                   toolBar.bounds.size.width - 2*kMargin, kLabelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.restorationIdentifier = NSStringFromClass(label.class);
    
    return label;
}

- (UITextField *)createAddressFieldWithToolBar:(UIToolbar *)toolBar
{
    const NSUInteger WIDTH_OF_NETWORK_ACTIVITY_ANIMATION=4;
    CGRect addressFrame = CGRectMake(kMargin, kSpacer*1.5 + kLabelHeight,
                                     toolBar.bounds.size.width - WIDTH_OF_NETWORK_ACTIVITY_ANIMATION*kMargin, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:17];
    if (self.settings.useAddressBarAsSearchBarWhenAddressNotFound) {
        address.keyboardType = UIKeyboardTypeDefault;
        
    } else {
        address.keyboardType = UIKeyboardTypeURL;
    }
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
    address.autocorrectionType = UITextAutocorrectionTypeNo;
    address.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [address addTarget:self
                action:@selector(loadAddress:event:)
      forControlEvents:UIControlEventEditingDidEndOnExit];
    
    address.restorationIdentifier = NSStringFromClass(address.class);
    
    return address;
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
    NSString *urlString = self.addressField.text;
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
    self.pageTitle.text = pageTitle;
}

- (void)updateAddress:(NSURL *)sourceURL
{
    if (NO==[self.webViewController isAddressAJavascriptEvaluation:sourceURL]) {
        if (NO==self.addressField.editing) {
            self.addressField.text = sourceURL.absoluteString;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    self.navigationBar.tintColor = self.barsTintColor;
    self.addressToolbar.tintColor = self.barsTintColor;
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
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.webViewController forKey:[SVModalWebViewController KEY_WEBVIEW_CONTROLLER]];
    
    [coder encodeObject:self.pageTitle forKey:NSStringFromClass(self.pageTitle.class)];
    [coder encodeObject:self.pageTitle.text forKey:[SVModalWebViewController KEY_PAGE_TITLE]];
    
    [coder encodeObject:self.addressField forKey:NSStringFromClass(self.addressField.class)];
    [coder encodeObject:self.addressField.text forKey:[SVModalWebViewController KEY_ADDRESS_FIELD]];
    
    [coder encodeObject:self.settings forKey:NSStringFromClass(SVWebSettings.class)];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.webViewController = [coder decodeObjectForKey:[SVModalWebViewController KEY_WEBVIEW_CONTROLLER]];
    
    self.pageTitle = [coder decodeObjectForKey:NSStringFromClass(UILabel.class)];
    self.pageTitle.text = [coder decodeObjectForKey:[SVModalWebViewController KEY_PAGE_TITLE]];
    
    self.addressField = [coder decodeObjectForKey:NSStringFromClass(UITextField.class)];
    self.addressField.text = [coder decodeObjectForKey:[SVModalWebViewController KEY_ADDRESS_FIELD]];
}

#pragma mark Key constants used by the coder.
+ (NSString *)KEY_WEBVIEW_CONTROLLER
{
    return @"KEY_WEBVIEW_CONTROLLER";
}

+ (NSString *)KEY_PAGE_TITLE
{
    return @"KEY_PAGE_TITLE";
}

+ (NSString *)KEY_ADDRESS_FIELD
{
    return @"KEY_ADDRESS_FIELD";
}

@end
