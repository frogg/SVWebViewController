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

@property (strong) SVAddressBarSettings *settings;

@property (strong) UIToolbar *addressToolbar;

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
    self.addressToolbar = [[UIToolbar alloc] initWithFrame:addressBarFrame];
    self.addressToolbar.restorationIdentifier = kAddressToolbar;
    self.addressToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.pageTitle =  [self createTitleWithNavBar:self.addressToolbar];
    [self.addressToolbar addSubview:self.pageTitle];
    
    self.addressField = [self createAddressFieldWithToolBar:self.addressToolbar];
    [self.addressToolbar addSubview:self.addressField];
    
    [self scrollingAddress:self.view withAddressBar:self.addressToolbar];
    
    [self.view addSubview:self.addressToolbar];
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
    translatedToGoogleSearchQuery = [NSString stringWithFormat:@"https://encrypted.google.com/search?q=%@",encodedSearchTerm];
    
    return translatedToGoogleSearchQuery;
}

#pragma mark - UI State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    SVAddressBar *thisViewController=nil;
    
    SVAddressBarSettings *settings = [coder decodeObjectForKey:NSStringFromClass(SVAddressBarSettings.class)];
    
    thisViewController = [[SVAddressBar alloc] initWithSettings:settings];
    thisViewController.restorationIdentifier = identifierComponents.lastObject;
    thisViewController.restorationClass = self.class;
    
    return thisViewController;
}

static NSString * const kPageTitle = @"kPageTitle";
static NSString * const kAddressField = @"kAddressField";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.pageTitle.text forKey:kPageTitle];
    [coder encodeObject:self.addressField.text forKey:kAddressField];
    
    [coder encodeObject:self.settings forKey:NSStringFromClass(SVAddressBarSettings.class)];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.pageTitle.text = [coder decodeObjectForKey:kPageTitle];
    self.addressField.text = [coder decodeObjectForKey:kAddressField];
}

@end
