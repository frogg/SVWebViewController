//
//  SVWebViewControllerDelegate.h
//  Videohog-iOS
//
//  Created by Ben Pettit on 14/01/13.
//  Copyright 2012 Digimulti. All rights reserved.
//

@class SVWebViewController;

@protocol SVWebViewControllerDelegate <NSObject>
@optional
- (UIBarButtonItem *)createCustomBarButton:(SVWebViewController *)webViewController;
- (void)historyChanged:(UIWebView *)webView;
@end
