//
//  SVHelper.m
//  Videohog-iOS
//
//  Created by Ben Pettit on 21/06/13.
//  Copyright (c) 2013 Digimulti PTY LTD. All rights reserved.
//

#import "SVHelper.h"


@implementation SVHelper

+ (NSMutableURLRequest *)requestForAttemptingHTTPS:(NSMutableURLRequest *)newRequest
{
    const NSTimeInterval smallIntervalForTestingHTTPSSupportInSeconds = 3;
    newRequest.timeoutInterval = smallIntervalForTestingHTTPSSupportInSeconds;
    
    return newRequest;
}

@end
