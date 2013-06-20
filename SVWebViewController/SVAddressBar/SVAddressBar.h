//
//  SVAddressBar.h
//  Videohog-iOS
//
//  Created by eggers on 20/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

@class SVAddressBarSettings;


@interface SVAddressBar : UIViewController

- (SVAddressBar *)initWithSettings:(SVAddressBarSettings *)settings;

@property (readonly, strong) UILabel *pageTitle;
@property (readonly, strong) UITextField *addressField;

@end
