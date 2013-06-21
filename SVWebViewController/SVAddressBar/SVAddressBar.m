//
//  SVAddressBar.m
//  Videohog-iOS
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVAddressBar.h"
#import "SVAddressBarSettings.h"


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
        self.settings = settings;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    CGRect addressBarBounds = self.view.bounds;
    addressBarBounds.size.height = kNavBarHeight+self.settings.scrollingYOffset;
    self.view.frame = addressBarBounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.view.restorationIdentifier = kSVAddressBar;
    
    CGRect addressBarFrame = self.view.bounds;
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
    if (self.settings.useAsSearchBarWhenAddressNotFound) {
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
