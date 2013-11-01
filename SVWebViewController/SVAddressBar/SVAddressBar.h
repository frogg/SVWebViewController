//
//  SVAddressBar.h
//
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//


@class SVAddressBarSettings;


@interface SVAddressBar : UIViewController

- (SVAddressBar *)initWithSettings:(SVAddressBarSettings *)settings;

#pragma mark Load the address in the address field.
- (void)loadAddress;

#pragma mark Update the addressbar title with a web view's current page title.
- (void)updateTitle:(UIWebView *)webView;
@property (nonatomic, strong, readonly) UILabel *pageTitle;

#pragma mark Update the address field with a url.
@property (nonatomic, strong) NSURL *addressURL;

@property (nonatomic) BOOL isHidden;

@end
