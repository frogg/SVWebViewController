//
//  SVWebViewController.h
//
//  Created by Ben Pettit on 24/06/2013
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import <MessageUI/MessageUI.h>

#import "SVModalWebViewController.h"
#import "SVAddressBarDelegate.h"

@class SVWebSettings, SVAddressBar;

@interface SVWebViewController : UIViewController <UIGestureRecognizerDelegate, UIWebViewDelegate, UIViewControllerRestoration, SVAddressBarDelegate>

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;
- (id)initWithURL:(NSURL *)URL withSettings:(SVWebSettings *)settings;

- (void)loadRequest:(NSMutableURLRequest *)request;
- (void)loadURL:(NSURL*)URL;
- (void)loadAddress:(NSString*)address;

- (void)updateToolbarItems:(BOOL)isLoading;

- (void)dismissPageActionSheet;

#pragma mark - Misc functions

#pragma mark Update the address in the nav bar.
- (void)updateAddress:(NSURL *)sourceURL;

#pragma mark Reload
- (void)reload;

- (BOOL)isAddressAJavascriptEvaluation:(NSURL *)sourceURL;

@property (nonatomic, readwrite) SVWebViewControllerAvailableActions availableActions;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) UIBarButtonItem *customBarButtonItem;
@property (nonatomic, strong, readonly) UIActionSheet *pageActionSheet;

#pragma mark Flag to show that the mainwebview is in restore state.
typedef NS_ENUM(NSInteger, MainWebViewRestoreState) {
    RestoreWebViewStateNone,
    RestoreWebViewStateLoadingFirstPage
};
@property (nonatomic, readonly) MainWebViewRestoreState restoredWebViewState;

@property (readonly) BOOL isSecureHTTPinUse;
@property (readonly) BOOL isLoadingPage;
@property (readonly, strong) NSString *currentPageAddress;

@property (nonatomic, strong) SVAddressBar *addressBar;

@end
