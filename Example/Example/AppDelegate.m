//
//  AppDelegate.m
//  Example
//
//  Created by Francesco Rossi on 11/17/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "AppDelegate.h"
#import <RdioSimpleApi/RdioSimpleApi.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
 	[[RdioSimpleApi shared] setupWithKey:@"<YOUR APP's RDIO KEY HERE>" andSecret:@"<YOUR APP SECRET HERE>"];
    
    //Opens a Safari window that asks to connect the app to Rdio. Once authorization is granted, Safari reopens the app using the URL scheme RdioSimpleApiExample://.
    [[RdioSimpleApi shared] authenticateInBrowserWithURLScheme:@"RdioSimpleApiExample" block:^(RdioSimpleApi *api, NSError *error) {
        
    }];
    
    [[RdioSimpleApi shared] me:^(NSDictionary *response, NSError *error) {
        //...
    }];
    
    [[RdioSimpleApi shared] call:@"search" parameters:@{
                                                        @"query":@"get lucky",
                                                        @"types":@"Track"
                                                        } block:^(NSDictionary *response, NSError *error) {
                                                            //...
                                                        }];
}

@end
