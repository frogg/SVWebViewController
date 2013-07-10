//
//  SVAddressBarSettings.m
//
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVAddressBarSettings.h"


@implementation SVAddressBarSettings

static const CGFloat kAlphaStandard = 0.75;
static const NSInteger kStatusBarHeight = 20;

- (SVAddressBarSettings *)init
{
    if (self = [super init]) {
        self.isUseAsSearchBarWhenAddressNotFound = YES;
        self.isHidden = NO;
        if (UIUserInterfaceIdiomPhone == [[UIDevice currentDevice] userInterfaceIdiom]) {
            self.isScrolling = NO;
            
        } else {
            self.isScrolling = NO;
        }
        self.scrollingYOffset = kStatusBarHeight;
        self.toolbarSpacingAlpha = kAlphaStandard;
    }
    self.isUseHTTPSWhenNotDefined = NO;
    
    return self;
}

- (void)dealloc
{
    _delegate = nil;
}

@end
