//
//  SVWebSettings.m
//
//
//  Created by Ben Pettit on 13/12/12.
//  Copyright 2012 Digimulti. All rights reserved.
//

#import "SVWebSettings.h"
#import "SVAddressBarSettings.h"

@implementation SVWebSettings

- (id)init
{
    self = [super init];
    
    if (nil!=self) {
        [self loadDefaults];
    }
    
    return self;
}

- (void)loadDefaults
{
    self.mediaAllowsInlineMediaPlayback = YES;
    self.mediaPlaybackAllowsAirPlay = YES;
    self.mediaPlaybackRequiresUserAction = YES;
    self.isUseHTTPSWhenPossible = NO;
    self.uiWebViewClassType = UIWebView.class;
    self.addressBar = [SVAddressBarSettings new];
}

#pragma mark - NSCoding
NSString * const UIWEBVIEW_CLASS_TYPE = @"uiWebViewClassType";

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    for (NSString *key in [self propertyKeys]) {
        id value = [self valueForKey:key];
        if ([key isEqualToString:UIWEBVIEW_CLASS_TYPE]) {
            NSString *className = NSStringFromClass(value);
            [aCoder encodeObject:className forKey:key];
        } else
            [aCoder encodeObject:value forKey:key];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [self init])) {
        for (NSString *key in [self propertyKeys]) {
            id value = [aDecoder decodeObjectForKey:key];
            if ([key isEqualToString:UIWEBVIEW_CLASS_TYPE]) {
                NSString *className = value;
                value = NSClassFromString(className);
            }
            [self setValue:value forKey:key];
        }
    }
    
    return self;
}

@end
