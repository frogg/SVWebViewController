//
//  SVAddressBarSettings.m
//  Videohog-iOS
//
//  Created by eggers on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVAddressBarSettings.h"


@implementation SVAddressBarSettings

static const CGFloat kAlphaStandard = 0.75;
static const NSInteger kStatusBarHeight = 20;

- (SVAddressBarSettings *)init
{
    if (self = [super init]) {
        self.useAsSearchBarWhenAddressNotFound = YES;
        self.isHidden = NO;
        self.isScrolling = YES;
        self.scrollingYOffset = kStatusBarHeight;
        self.toolbarSpacingAlpha = kAlphaStandard;
    }
    return self;
}

@end
