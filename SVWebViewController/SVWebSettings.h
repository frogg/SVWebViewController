//
//  SVWebSettings.h
//  SVWeb
//
//  Created by Ben Pettit on 13/12/12.
//  Copyright 2012 Digimulti. All rights reserved.
//

#import "SVWebViewControllerDelegate.h"


@class SVAddressBarSettings;


@interface SVWebSettings : NSObject <NSCoding>

@property BOOL mediaPlaybackRequiresUserAction;
@property BOOL mediaAllowsInlineMediaPlayback;
@property BOOL mediaPlaybackAllowsAirPlay;
@property BOOL isSwipeBackAndForward;
@property BOOL isUseHTTPSWhenPossible;

@property SVAddressBarSettings *addressBar;

@property (nonatomic) id uiWebViewClassType;
@property (strong) id<UIWebViewDelegate, SVWebViewControllerDelegate> delegate;

@end
