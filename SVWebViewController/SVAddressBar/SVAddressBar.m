//
//  SVAddressBar.m
//
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVAddressBar.h"
#import "SVAddressBarSettings.h"
#import "SVHelper.h"


#pragma mark - Private Declaration

static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 1.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;
static const CGFloat kNavBarHeight = kSpacer*4 + kLabelHeight + kAddressHeight;

#pragma mark UI Restoration keys
static NSString * const kSVAddressBar = @"kSVAddressBar";
static NSString * const kAddressToolbar = @"kAddressToolbar";


@interface SVAddressBar()

@property (strong) UILabel *pageTitle;
@property (strong) UITextField *addressField;

@property (strong, nonatomic) SVAddressBarSettings *settings;

@property (strong, nonatomic) UIToolbar *addressToolbar;

@end


#pragma mark - Definition

@implementation SVAddressBar


- (SVAddressBar *)initWithSettings:(SVAddressBarSettings *)settings
{
    if (self = [self init]) {
        NSAssert([settings.delegate conformsToProtocol:@protocol(SVAddressBarDelegate)], @"A delegate which conforms to the SVAddressBarDelegate has not yet been set.");
        self.settings = settings;
    }
    return self;
}


#pragma mark - Public methods

- (void)setAddressURL:(NSURL *)address
{
    if (NO==self.addressField.editing) {
        self.addressField.text = address.absoluteString;
    }
    _addressURL = address;
}

- (void)loadAddress
{
    NSMutableURLRequest* request;
    NSString *urlString = self.addressField.text;
    if (NSNotFound!=[urlString rangeOfString:@" "].location
        || NSNotFound==[urlString rangeOfString:@"."].location) {
        urlString = [self getSearchQuery:urlString];
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
    } else {
        if (0 ==[urlString rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            
        } else if (0 ==[urlString rangeOfString:@"https://" options:NSCaseInsensitiveSearch].location) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            
        } else {
            if (self.settings.isUseHTTPSWhenNotDefined) {
                urlString = [@"https://" stringByAppendingString:urlString];
                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                request = [SVHelper requestForAttemptingHTTPS:request];
                
            } else {
                urlString = [@"http://" stringByAppendingString:urlString];
                request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            }
        }
    }
    
    [self.settings.delegate addressModified:request];
}

- (void)updateTitle:(UIWebView *)webView
{
    self.pageTitle.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}


#pragma mark - View setup

- (void)loadView
{
    [super loadView];
    
    CGRect addressBarBounds = self.view.bounds;
    addressBarBounds.size.height = kNavBarHeight+self.settings.scrollingYOffset;
    self.view.frame = addressBarBounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.view.restorationIdentifier = kSVAddressBar;
    [self.view setClipsToBounds:YES];
    
    CGRect addressBarFrame = self.view.frame;
    addressBarFrame.size.height = kNavBarHeight;
    addressBarFrame.origin.y = self.settings.scrollingYOffset;
    
    UIView *toolbarBackground = [[UIView alloc] initWithFrame:addressBarBounds];
    toolbarBackground.backgroundColor = [UIColor grayColor];
    [self.view addSubview:toolbarBackground];
    
    self.addressToolbar = [[UIToolbar alloc] initWithFrame:addressBarFrame];
    self.addressToolbar.restorationIdentifier = kAddressToolbar;
    self.addressToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.pageTitle =  [self createTitleWithNavBar:self.addressToolbar];
    [self.addressToolbar addSubview:self.pageTitle];
    
    self.addressField = [self createAddressFieldWithToolBar:self.addressToolbar];
    [self.addressToolbar addSubview:self.addressField];
    
    [self scrollingAddress:self.view withAddressBar:self.addressToolbar];
    
    [self.view addSubview:self.addressToolbar];
    
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-0.5, self.view.bounds.size.width, 0.5)];
    bottomBorder.backgroundColor = [UIColor blackColor];
    bottomBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:bottomBorder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.settings.tintColor) {
        self.addressToolbar.backgroundColor = self.settings.tintColor;
    }
}


#pragma mark Scrolling addressbar

- (void)scrollingAddress:(UIView *)container withAddressBar:(UIToolbar *)addressBar
{
    if (0!=self.settings.toolbarSpacingAlpha) {
        CGRect webViewColorFrame;
        webViewColorFrame.size.width = self.view.frame.size.width;
        webViewColorFrame.size.height = self.settings.scrollingYOffset;
        UIView *webViewColor = [[UIView alloc] initWithFrame:webViewColorFrame];
        webViewColor.backgroundColor = self.settings.webViewBackgroundColor;
        [container addSubview:webViewColor];
    }
    
    CGRect addressBarFrame = addressBar.frame;
    addressBarFrame.origin.y = self.settings.scrollingYOffset;
    addressBarFrame.size.width = self.view.frame.size.width;
    addressBar.frame = addressBarFrame;
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
    if (self.settings.isUseAsSearchBarWhenAddressNotFound) {
        NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
        if ( 7 >= [[versionCompatibility objectAtIndex:0] intValue] ) {
            address.keyboardType = UIKeyboardTypeWebSearch;
            
        } else {
            address.keyboardType = UIKeyboardTypeDefault;
        }
        
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

- (void)setIsHidden:(BOOL)isHidden
{
    CGRect addressBarBounds = self.view.frame;
    if (isHidden) {
        addressBarBounds.size.height = 0;
        _isHidden=YES;
        
    } else {
        addressBarBounds.size.height = kNavBarHeight+self.settings.scrollingYOffset;
        _isHidden=NO;
    }
    self.view.frame = addressBarBounds;
    
    [self.settings.delegate addressBarHidden:isHidden];
}

#pragma mark - Privates

- (void)loadAddress:(id)sender event:(UIEvent *)event
{
    [self loadAddress];
}

- (NSString *)getSearchQuery:(NSString *)urlString
{
    NSString *translatedToGoogleSearchQuery=nil;
    
    NSString *encodedSearchTerm = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];

    NSString *searchString;
    if (self.settings.customSearchString) {
        searchString = self.settings.customSearchString;
    } else {
        searchString = @"https://encrypted.google.com/search?q=";
    }
    translatedToGoogleSearchQuery = [NSString stringWithFormat:@"%@%@",searchString,encodedSearchTerm];
    
    return translatedToGoogleSearchQuery;
}

@end
