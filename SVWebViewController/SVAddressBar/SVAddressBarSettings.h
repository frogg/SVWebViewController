//
//  SVAddressBarSettings.h
//
//
//  Created by Ben Pettit on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVSettings.h"
#import "SVAddressBarDelegate.h"


@interface SVAddressBarSettings : SVSettings

@property BOOL isUseHTTPSWhenNotDefined;
@property BOOL isUseAsSearchBarWhenAddressNotFound;
@property (nonatomic, strong) NSString *customSearchString;
@property BOOL isHidden;

@property BOOL isScrolling;
@property CGFloat toolbarSpacingAlpha;
@property CGFloat scrollingYOffset;
@property (strong) UIColor *webViewBackgroundColor;

@property (strong) UIColor *tintColor;

@property (strong) NSObject<SVAddressBarDelegate> *delegate;

@end