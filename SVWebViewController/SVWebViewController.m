//
//  SVWebViewController.m
//
//  Created by Ben Pettit on 24/06/2013
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//
//  https://github.com/pellet/SVWebViewController

#import "SVWebViewController.h"
#import "SVWebSettings.h"
#import "SVModalWebViewController.h"
#import "SVAddressBar.h"
#import "SVAddressBarSettings.h"
#import "SVHelper.h"

@interface SVWebViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UISplitViewControllerDelegate>

@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *actionBarButtonItem;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, strong) UIWebView *mainWebView;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) SVWebSettings *settings;

@property BOOL isLoadingPage;
@property (strong) NSString *currentPageAddress;

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;

- (void)updateToolbarItems:(BOOL)isLoading;

- (void)goBackClicked:(UIBarButtonItem *)sender;
- (void)goForwardClicked:(UIBarButtonItem *)sender;
- (void)reloadClicked:(UIBarButtonItem *)sender;
- (void)stopClicked:(UIBarButtonItem *)sender;
- (void)actionButtonClicked:(UIBarButtonItem *)sender;

@property (strong) UIView *testView;

@end


@implementation SVWebViewController

@synthesize availableActions;

@synthesize mainWebView, customBarButtonItem;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, actionBarButtonItem, pageActionSheet;

#pragma mark - setters and getters

- (UIBarButtonItem *)backBarButtonItem {
    
    if (!backBarButtonItem) {
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBackClicked:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		backBarButtonItem.width = 18.0f;
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForwardClicked:)];
        forwardBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		forwardBarButtonItem.width = 18.0f;
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    
    if (!refreshBarButtonItem) {
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    
    if (!stopBarButtonItem) {
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    
    if (!actionBarButtonItem) {
        actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    }
    return actionBarButtonItem;
}

- (UIBarButtonItem *)customBarButtonItem {
    
    if (nil==customBarButtonItem) {
        if ([self.settings.delegate respondsToSelector:@selector(createCustomBarButton:)]) {
            customBarButtonItem = [self.settings.delegate performSelector:@selector(createCustomBarButton:) withObject:self];
        }
    }
    
    return customBarButtonItem;
}

- (UIActionSheet *)pageActionSheet {
    
    if(!pageActionSheet) {
        pageActionSheet = [[UIActionSheet alloc]
                           initWithTitle:self.currentPageAddress
                           delegate:self
                           cancelButtonTitle:nil
                           destructiveButtonTitle:nil
                           otherButtonTitles:nil];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsCopyLink) == SVWebViewControllerAvailableActionsCopyLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedString(@"Copy Link", @"")];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsOpenInSafari) == SVWebViewControllerAvailableActionsOpenInSafari)
            [pageActionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", @"")];
        
        if([MFMailComposeViewController canSendMail] && (self.availableActions & SVWebViewControllerAvailableActionsMailLink) == SVWebViewControllerAvailableActionsMailLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedString(@"Mail Link to this Page", @"")];
        
        [pageActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        pageActionSheet.cancelButtonIndex = [self.pageActionSheet numberOfButtons]-1;
    }
    
    return pageActionSheet;
}


#pragma mark - Initialization

- (id)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL*)pageURL {
    
    if(self = [super init]) {
        self.settings = [SVWebSettings new];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            [backButton setImage:[UIImage imageNamed:@"BackButton"]  forState:UIControlStateNormal];
            [backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        }
        self.URL = pageURL;
        self.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsMailLink;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.restorationClass = self.class;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(progressEstimateChanged:)
                                                     name:@"WebProgressEstimateChangedNotification"
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(historyChanged:)
                                                     name:@"WebHistoryItemChangedNotification"
                                                   object:nil];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)URL withSettings:(SVWebSettings *)settings
{
    self = [self initWithURL:URL];
    
    if (nil!=self) {
        self.settings = settings;
    }
    
    return self;
}

- (void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loadRequest:(NSMutableURLRequest *)request
{
    [NSURLProtocol setProperty:@"YES" forKey:kMainDocumentURL inRequest:request];
    if ([request.URL.scheme isEqualToString:@"http"]) {
        [NSURLProtocol setProperty:@"YES" forKey:kHTTPSNotSupported inRequest:request];
    }
    
    [mainWebView loadRequest:request];
    
    self.URL = request.URL;
}

- (void)loadURL:(NSURL*)url
{
    [self loadRequest:[NSMutableURLRequest requestWithURL:url]];
}

- (void)loadAddress:(NSString*)address;
{
    [self loadURL:[NSURL URLWithString:address]];
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
        //    self.settings.addressBar.webViewBackgroundColor = self.mainWebView.backgroundColor;
    self.settings.addressBar.isUseHTTPSWhenNotDefined = self.settings.isUseHTTPSWhenPossible;
    self.settings.addressBar.delegate = self;
    self.addressBar = [[SVAddressBar alloc] initWithSettings:self.settings.addressBar];
    
    [self addChildViewController:self.addressBar];
    [self.view addSubview:self.addressBar.view];
    [self.addressBar didMoveToParentViewController:self];
    
    self.mainWebView = [self.settings.uiWebViewClassType new];
    [self.mainWebView setClipsToBounds:YES];
    self.mainWebView.restorationIdentifier=NSStringFromClass(self.mainWebView.class);
    
    if (self.settings.addressBar.isScrolling) {
        [self.mainWebView.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    if (nil!=self.URL) {
        [self loadURL:self.URL];
    }
    
    self.mainWebView.delegate = self;
    self.mainWebView.scalesPageToFit = YES;
    
    [self setupMediaSettings];
    
    [self.view addSubview:self.mainWebView];
    
    CGRect spacingForStatusBar;
    spacingForStatusBar.size.height = self.settings.addressBar.scrollingYOffset;
    spacingForStatusBar.size.width = self.view.frame.size.width;
    UIToolbar *statusBarOverlay = [[UIToolbar alloc] initWithFrame:spacingForStatusBar];
    statusBarOverlay.alpha = self.settings.addressBar.toolbarSpacingAlpha;
    statusBarOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:statusBarOverlay];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.indicator.hidesWhenStopped = YES;
    [self.indicator stopAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.indicator];
    
    [self updateToolbarItems:self.mainWebView.isLoading];
    
}

- (void)viewWillLayoutSubviews
{
    CGRect addressBarFrame = self.addressBar.view.frame;
    addressBarFrame.size.width = self.view.frame.size.width;
    self.addressBar.view.frame = addressBarFrame;
    
    CGRect webFrame = self.view.bounds;
    webFrame.origin.y = self.addressBar.view.frame.size.height;
    webFrame.origin.x = 0;
    webFrame.size.width = self.view.frame.size.width;
    webFrame.size.height = self.view.frame.size.height-self.addressBar.view.frame.size.height;
    self.mainWebView.frame = webFrame;
    
}

- (void)viewWillAppear:(BOOL)animated {
    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
	[super viewWillAppear:animated];
	
    self.indicator.center = self.mainWebView.center;
    
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)dealloc
{
    [mainWebView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    mainWebView.delegate = nil;
}


#pragma mark - Media player settings

- (void)setupMediaSettings
{
    mainWebView.mediaPlaybackRequiresUserAction = self.settings.mediaPlaybackRequiresUserAction;
    mainWebView.allowsInlineMediaPlayback = self.settings.mediaAllowsInlineMediaPlayback;
    if([mainWebView respondsToSelector:@selector(mediaPlaybackAllowsAirPlay)])
        mainWebView.mediaPlaybackAllowsAirPlay = self.settings.mediaPlaybackAllowsAirPlay;
}


#pragma mark - Addressbar

- (void)updateAddress:(NSURL *)sourceURL
{
    if (NO==[self isAddressAJavascriptEvaluation:sourceURL]) {
        self.addressBar.addressURL = sourceURL;
    }
}

#pragma mark SVAddressBarDelegate methods

- (void)addressModified:(NSMutableURLRequest *)request
{
    [self updateAddress:request.URL];
    
    [self loadRequest:request];
}

- (void)addressBarHidden:(BOOL)isHidden
{
}

#pragma mark Scrolling address bar

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
        [self scrollViewDidScroll];
}

- (void)scrollViewDidScroll
{
    if (self.mainWebView.scrollView.contentOffset.y<-self.addressBar.view.frame.size.height-self.settings.addressBar.scrollingYOffset) {
            self.addressBar.view.frame = CGRectMake(0, 0, self.addressBar.view.frame.size.width, self.addressBar.view.frame.size.height);
            
        } else {
        CGRect addressBarFrame = self.addressBar.view.frame;
        addressBarFrame.origin.y = -self.mainWebView.scrollView.contentOffset.y-self.addressBar.view.frame.size.height-self.settings.addressBar.scrollingYOffset;
        self.addressBar.view.frame = addressBarFrame;
    }
}


#pragma mark - Toolbar
#pragma mark UIWebView.isLoading returns YES when a page has successfully finished loading via HTML5, ie a custom argument is used.
- (void)updateToolbarItems:(BOOL)isLoading {
    self.backBarButtonItem.enabled = self.mainWebView.canGoBack;
    self.forwardBarButtonItem.enabled = self.mainWebView.canGoForward;
    self.actionBarButtonItem.enabled = NO==isLoading;
    self.refreshBarButtonItem.enabled = YES;
    
    UIBarButtonItem *refreshStopBarButtonItem = isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    NSMutableArray *items = [NSMutableArray arrayWithObjects:
                 fixedSpace,
                 self.backBarButtonItem,
                 flexibleSpace,
                 self.forwardBarButtonItem,
                 flexibleSpace,
                 refreshStopBarButtonItem,
                 fixedSpace,
                 nil];
    
    if(0!=self.availableActions) {
        [items insertObject:flexibleSpace atIndex:items.count-1];
        [items insertObject:self.actionBarButtonItem atIndex:items.count-1];
    }
    
    if (nil!=self.customBarButtonItem) {
        self.customBarButtonItem.enabled = YES;
        [items insertObject:flexibleSpace atIndex:items.count-1];
        [items insertObject:self.customBarButtonItem atIndex:items.count-1];
    }
    
    self.toolbarItems = items;
}


#pragma mark - UIWebViewDelegate

NSString * const kMainDocumentURL = @"kMainDocumentURL";
NSString * const kHTTPSNotSupported = @"kHTTPSNotSupported";

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isStartLoad=YES;
    
    if (nil!=self.settings.delegate) {
        if ([self.settings.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
            isStartLoad = [self.settings.delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        }
    }
    
    if (UIWebViewNavigationTypeLinkClicked==navigationType) {
        NSMutableURLRequest *modifiedRequest = (NSMutableURLRequest *)request;
        [NSURLProtocol setProperty:@"YES" forKey:kMainDocumentURL inRequest:modifiedRequest];
    }
    
    if (isStartLoad) {
        BOOL isSecureSupportUnknownforNavType = (UIWebViewNavigationTypeLinkClicked == navigationType || UIWebViewNavigationTypeOther==navigationType);
        
        if (self.settings.isUseHTTPSWhenPossible
            && [request.URL.scheme isEqualToString:@"http"]
            && isSecureSupportUnknownforNavType
            && nil==[request.allHTTPHeaderFields objectForKey:@"Referer"]
            ) {
            NSString *isHTTPSNotSupported = [NSURLProtocol propertyForKey:kHTTPSNotSupported inRequest:request];
            NSString *isMainDocumentURL = [NSURLProtocol propertyForKey:kMainDocumentURL inRequest:request];
            if (nil==isHTTPSNotSupported && isMainDocumentURL) {
                NSRange range = [request.URL.absoluteString rangeOfString:@"http://"];
                NSString *newURLAddress = [request.URL.absoluteString stringByReplacingCharactersInRange:range withString:@"https://"];
                
                if (NO==[newURLAddress isEqualToString:self.URL.absoluteString]) {
                    NSRange range = [request.mainDocumentURL.absoluteString rangeOfString:@"http://"];
                    NSString *newMainURLAddress = [request.mainDocumentURL.absoluteString stringByReplacingCharactersInRange:range withString:@"https://"];
                    
                    NSMutableURLRequest *newRequest = (NSMutableURLRequest *)request;
                    newRequest.URL = [NSURL URLWithString:newURLAddress];
                    newRequest.mainDocumentURL = [NSURL URLWithString:newMainURLAddress];
                    
                    newRequest = [SVHelper requestForAttemptingHTTPS:newRequest];
                    
                    [self loadRequest:newRequest];
                    
                    isStartLoad=NO;
                }
            }
            
        }
    }
    
    if (isStartLoad) {
        
        if (NO==[self isAddressAJavascriptEvaluation:request.URL]) {
            self.URL = request.URL;
        }
    }
    
    self.isLoadingPage=isStartLoad;
    
    return isStartLoad;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    if (nil!=self.settings.delegate) {
        if ([self.settings.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
            [self.settings.delegate webViewDidStartLoad:webView];
        }
    }
    
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.indicator startAnimating];
    
    [self updateToolbarItems:webView.isLoading];
}

#pragma mark This delegate function is not always called when pages are loaded via html5 e.g. youtube.
- (void)webViewDidFinishLoad:(UIWebView *)webView {
}
NSString * const PROGRESS_ESTIMATE_KEY=@"WebProgressEstimatedProgressKey";
- (void)progressEstimateChanged:(NSNotification *)note
{
    NSNumber *progress = [note.userInfo objectForKey:PROGRESS_ESTIMATE_KEY];
    const NSInteger LOADING_COMPLETE=1;
    if (self.isLoadingPage && LOADING_COMPLETE==progress.integerValue) {
        self.isLoadingPage=NO;
        [self finishedLoadingPage:self.mainWebView];
    }
}

- (void)finishedLoadingPage:(UIWebView *)webView
{
    if (nil!=self.settings.delegate) {
        if ([self.settings.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
            [self.settings.delegate webViewDidFinishLoad:self.mainWebView];
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.indicator stopAnimating];
    
    [self updateToolbarItems:NO];
}

#pragma mark Catch this notification to update the availability of canGoBack and canGoForward.
- (void)historyChanged:(NSNotification *)note
{
    self.currentPageAddress = [self.mainWebView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    if (nil!=self.settings.delegate) {
        if ([self.settings.delegate respondsToSelector:@selector(historyChanged:)]) {
            [self.settings.delegate historyChanged:self.mainWebView];
        }
    }
    [self updateToolbarItems:self.isLoadingPage];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbarItems:self.mainWebView.isLoading];
    
    BOOL quietlyHandledError=NO;
    
    const NSInteger REQUEST_TIMED_OUT = -1001;
    const NSInteger COULDNT_CONNECT_TO_THE_SERVER_CODE=-1004;
    switch (error.code) {
        case COULDNT_CONNECT_TO_THE_SERVER_CODE:
        case REQUEST_TIMED_OUT:
        {
        if (self.settings.isUseHTTPSWhenPossible) {
            NSMutableURLRequest *httpRequest = [self convertHTTPStoHTTP:self.URL];
            [self loadRequest:httpRequest];
            quietlyHandledError=YES;
        }
        }break;
    }
    
    if (nil!=self.settings.delegate
    && NO==quietlyHandledError) {
        if ([self.settings.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
            [self.settings.delegate webView:webView didFailLoadWithError:error];
        }
    }
}


#pragma mark - Target actions

- (void)goBackClicked:(UIBarButtonItem *)sender {
    [mainWebView goBack];
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [mainWebView goForward];
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    [mainWebView reload];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [mainWebView stopLoading];
	[self updateToolbarItems:NO];
}

- (void)actionButtonClicked:(id)sender {
    
    if(pageActionSheet)
        pageActionSheet=nil;
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.pageActionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
    else
        [self.pageActionSheet showFromToolbar:self.navigationController.toolbar];
    
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if([title isEqualToString:NSLocalizedString(@"Open in Safari", @"")])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.currentPageAddress]];
    
    if([title isEqualToString:NSLocalizedString(@"Copy Link", @"")]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.currentPageAddress;
    }
    
    else if([title isEqualToString:NSLocalizedString(@"Mail Link to this Page", @"")]) {
        
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        
		mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:[self.mainWebView stringByEvaluatingJavaScriptFromString:@"document.title"]];
  		[mailViewController setMessageBody:self.currentPageAddress isHTML:NO];
		mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentViewController:mailViewController animated:YES completion:NULL];
	}
    
    pageActionSheet = nil;
}

- (void)dismissPageActionSheet
{
    NSInteger cancelButtonIndex = [self.pageActionSheet numberOfButtons]-1;
    [self.pageActionSheet dismissWithClickedButtonIndex:cancelButtonIndex animated:YES];
    pageActionSheet=nil;
}


#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UI State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    SVWebViewController *thisViewController=nil;
    
    if ([[identifierComponents objectAtIndex:0] isEqualToString:NSStringFromClass(SVModalWebViewController.class)]) {
        SVModalWebViewController *modalView = [coder decodeObjectForKey:NSStringFromClass(UINavigationController.class)];
        thisViewController = modalView.webViewController;
        
    } else {
        SVWebSettings *settings = [coder decodeObjectForKey:NSStringFromClass(SVWebSettings.class)];
        thisViewController = [[SVWebViewController alloc] initWithURL:nil withSettings:settings];
        thisViewController.restorationIdentifier = identifierComponents.lastObject;
        thisViewController.restorationClass = self.class;
    }
    
    return thisViewController;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.navigationController forKey:NSStringFromClass(UINavigationController.class)];
    
    [coder encodeObject:self.settings forKey:NSStringFromClass(self.settings.class)];
    [coder encodeObject:self.URL forKey:[SVWebViewController KEY_URL]];
    [coder encodeObject:self.mainWebView forKey:[SVWebViewController KEY_WEBVIEW]];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.URL = [coder decodeObjectForKey:[SVWebViewController KEY_URL]];
    self.mainWebView = [coder decodeObjectForKey:[SVWebViewController KEY_WEBVIEW]];
}

+ (NSString *)KEY_URL
{
    return @"URL";
}

+ (NSString *)KEY_WEBVIEW
{
    return @"WEBVIEW";
}


#pragma mark - Misc functions

- (void)reload
{
    [self.mainWebView reload];
}

- (BOOL)isAddressAJavascriptEvaluation:(NSURL *)sourceURL
{
    BOOL isJSEvaluation=NO;
    
    if ([sourceURL.absoluteString isEqualToString:@"about:blank"]) {
        isJSEvaluation=YES;
    }
    
    return isJSEvaluation;
}

- (NSMutableURLRequest *)convertHTTPStoHTTP:(NSURL *)url
{
    NSMutableURLRequest *redirectedRequest;
    
    NSString *originalRequestString = url.absoluteString;
    
    NSString *newRequestString = [originalRequestString stringByReplacingOccurrencesOfString:@"https://" withString:@"http://"];
    
    redirectedRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:newRequestString]];
    
    [NSURLProtocol setProperty:@"YES" forKey:kHTTPSNotSupported inRequest:redirectedRequest];
    
    return redirectedRequest;
}

@end
