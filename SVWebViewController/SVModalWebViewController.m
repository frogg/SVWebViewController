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

@property (nonatomic, retain) UILabel* pageTitle;
@property (nonatomic, retain) UITextField* addressField;
@property (nonatomic, strong) SVWebSettings *settings;

@end

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 1.0f;//2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;


@implementation SVModalWebViewController

#pragma mark - Initialization

- (id)initWithAddress:(NSString*)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL *)URL {
    self.settings = [SVWebSettings new];
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL withSettings:self.settings];
    self = [self initWebViewController:webViewController];
    
    
    return self;
}

- (id)initWithURL:(NSURL *)URL withSettings:(SVWebSettings *)settings {
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithURL:URL withSettings:settings];
    self = [self initWebViewController:webViewController];
    
    self.settings = settings;
    
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
    
    CGRect navBarFrame = self.view.bounds;
    navBarFrame.size.height = kNavBarHeight;
    
    self.navigationBar.frame = navBarFrame;
    self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.pageTitle =  [self createTitleWithNavBar:self.navigationBar];
    [self.navigationBar addSubview:self.pageTitle];
    
    self.addressField = [self createAddressFieldWithNavBar:self.navigationBar];
    [self.navigationBar addSubview:self.addressField];
    
//    self.view.restorationIdentifier = @"derp2";
}

- (UILabel *)createTitleWithNavBar:(UINavigationBar *)navBar
{
    CGRect labelFrame = CGRectMake(kMargin, kSpacer,
                                   navBar.bounds.size.width - 2*kMargin, kLabelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.restorationIdentifier = NSStringFromClass(label.class);
    
    return label;
}

- (UITextField *)createAddressFieldWithNavBar:(UINavigationBar *)navBar
{
    const NSUInteger WIDTH_OF_NETWORK_ACTIVITY_ANIMATION=4;
    CGRect addressFrame = CGRectMake(kMargin, kSpacer*1.5 + kLabelHeight,
                                     navBar.bounds.size.width - WIDTH_OF_NETWORK_ACTIVITY_ANIMATION*kMargin, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:17];
    
    address.keyboardType = UIKeyboardTypeURL;
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
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
    NSString *urlString = self.addressField.text.lowercaseString;
    
    if (NSNotFound!=[urlString rangeOfString:@" "].location
        || NSNotFound==[urlString rangeOfString:@"."].location) {
        urlString = [self.webViewController getSearchQuery:urlString];
        
    } else {
        BOOL httpProtocolNameFound=NO;
        if (0 ==[urlString rangeOfString:@"http://"].location) {
            httpProtocolNameFound=YES;
            
        } else if (0 ==[urlString rangeOfString:@"https://"].location) {
            httpProtocolNameFound=YES;
        }
        
        if (NO==httpProtocolNameFound) {
            if (self.settings.isUseHTTPSWhenPossible) {
                urlString = [@"https://" stringByAppendingString:urlString];
                
            } else {
                urlString = [@"http://" stringByAppendingString:urlString];
            }
        }
    }
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self updateAddress:request.URL];
    
    [self.webViewController loadURL:request.URL];
}

- (void)updateTitle:(UIWebView *)webView
{
    NSString* pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.pageTitle.text = pageTitle;
}

- (void)updateAddress:(NSURL *)sourceURL
{
    if (NO==[self.webViewController isAddressAJavascriptEvaluation:sourceURL]) {
        if (NO==[self.addressField.text isEqualToString:sourceURL.absoluteString]) {
            if (NO==self.addressField.editing) {
                self.addressField.text = sourceURL.absoluteString;
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    self.navigationBar.tintColor = self.barsTintColor;
}

- (void)setAvailableActions:(SVWebViewControllerAvailableActions)newAvailableActions {
    self.webViewController.availableActions = newAvailableActions;
}

- (void)viewWillLayoutSubviews
{
    [self landscapeOrientationBugFixForExitingFullscreenVideoAndMailingLink:self.view];
    [self bugFixForBarButtonsBeingRemovedByActionSheet];
}

- (void)bugFixForBarButtonsBeingRemovedByActionSheet
{
    self.webViewController.toolbarItems=0;
    [self.webViewController updateToolbarItems:self.webViewController.isLoadingPage];
}

- (void)landscapeOrientationBugFixForExitingFullscreenVideoAndMailingLink:(UIView *)view
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    const CGFloat STATUS_BAR_HEIGHT = 20;
    CGRect screenBounds = self.view.bounds;
    if (UIDeviceOrientationIsLandscape(orientation)
    && (screenBounds.size.height==screenBounds.size.width
        || (screenBounds.size.height+STATUS_BAR_HEIGHT)==screenBounds.size.width)) {
        CGPoint center;
        center.x = (screenBounds.size.width+STATUS_BAR_HEIGHT)/2;
        center.y = self.view.center.y;
        
        screenBounds.size.width = [UIScreen mainScreen].bounds.size.height;
        screenBounds.size.height = [UIScreen mainScreen].bounds.size.width-STATUS_BAR_HEIGHT;
        
        self.view.bounds = screenBounds;
        self.view.center = center;
        [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    }
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
