//
//  SVWebSettings.h
//
//
//  Created by Ben Pettit on 13/12/12.
//  Copyright 2012 Digimulti. All rights reserved.
//

#import "SVWebViewControllerDelegate.h"
#import "SVSettings.h"


@class SVAddressBarSettings;


@interface SVWebSettings : SVSettings

@property BOOL mediaPlaybackRequiresUserAction;
@property BOOL mediaAllowsInlineMediaPlayback;
@property BOOL mediaPlaybackAllowsAirPlay;
@property BOOL isUseHTTPSWhenPossible;

@property SVAddressBarSettings *addressBar;

@property (nonatomic) id uiWebViewClassType;
@property (strong) id<UIWebViewDelegate, SVWebViewControllerDelegate> delegate;

@end
