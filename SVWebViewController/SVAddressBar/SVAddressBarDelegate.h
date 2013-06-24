//
//  SVAddressBarDelegate.h
//  Videohog-iOS
//
//  Created by eggers on 21/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

@protocol SVAddressBarDelegate <NSObject>

- (void)addressModified:(NSMutableURLRequest *)request;

- (void)addressBarHidden:(BOOL)isHidden;

@end
