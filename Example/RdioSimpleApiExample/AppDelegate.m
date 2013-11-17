//
//  AppDelegate.m
//  RdioSimpleApiExample
//
//  Created by Francesco Rossi on 11/16/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "AppDelegate.h"
#import <RdioSimpleApi/RdioSimpleApi.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [[RdioSimpleApi shared] setupWithKey:@"8jz6wx5dujdw3g5jy75ygdy3" andSecret:@"VQ7knTNKEb"];
    
    [[RdioSimpleApi shared] authenticateInBrowserWithURLScheme:@"RdioSimpleApiExample" block:^(RdioSimpleApi *api, NSError *error) {
        
    }];
    
    [[RdioSimpleApi shared] me:^(NSDictionary *response, NSError *error) {
        NSLog(@"resp=%@ err=%@", response, error);
    }];
    
    [[RdioSimpleApi shared] call:@"search" parameters:@{
                                                        @"query":@"get lucky",
                                                        @"types":@"Track"
                                                        } block:^(NSDictionary *response, NSError *error) {
        NSLog(@"resp=%@ err=%@", response, error);
    }];
    
    
    
    // Insert code here to initialize your application
}

@end
