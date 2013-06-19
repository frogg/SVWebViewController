//
//  SVWebSettings.h
//  SVWeb
//
//  Created by Ben Pettit on 13/12/12.
//  Copyright 2012 Digimulti. All rights reserved.
//

#import "SVWebViewControllerDelegate.h"

@interface SVWebSettings : NSObject <NSCoding>

@property BOOL mediaPlaybackRequiresUserAction;
@property BOOL mediaAllowsInlineMediaPlayback;
@property BOOL mediaPlaybackAllowsAirPlay;
@property BOOL isSwipeBackAndForward;
@property BOOL useAddressBarAsSearchBarWhenAddressNotFound;
@property BOOL isUseHTTPSWhenPossible;
@property BOOL isShowAddressBar;

#pragma mark Scrolling address bar settings.
@property BOOL isScrollingAddressBar;
@property CGFloat toolbarSpacingAlpha;
@property CGFloat scrollingAddressBarYOffset;

@property (nonatomic) id uiWebViewClassType;
@property (strong) id<UIWebViewDelegate, SVWebViewControllerDelegate> delegate;

@end
