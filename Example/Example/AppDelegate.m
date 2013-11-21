//
//  AppDelegate.m
//  Example
//
//  Created by Francesco Rossi on 11/17/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "AppDelegate.h"
#import <RdioSimpleApi/RdioSimpleApi.h>
#import "PlayerViewController.h"

@interface AppDelegate ()
{
    PlayerViewController* playerVC;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
#error set your API keys here and remove this line!
 	[[RdioSimpleApi shared] setupWithKey:@"<YOUR APP's RDIO KEY HERE>" andSecret:@"<YOUR APP SECRET HERE>"];

    //Opens a Safari window that asks to connect the app to Rdio. Once authorization is granted, Safari reopens the app using the URL scheme RdioSimpleApiExample://.
    
#error TODO change the player URL to a page hosted by yourself
    playerVC = [[PlayerViewController alloc]initWithPlayerURL:@"https://raw.github.com/redsh/RdioSimpleApiMac/master/static/rdioplayer.html"];
    
    [self.window setContentView:playerVC.view];
    
    
    [[RdioSimpleApi shared] authenticateInBrowserWithURLScheme:@"RdioSimpleApiExample" block:^(RdioSimpleApi *api, NSError *error) {
        
        [[RdioSimpleApi shared] me:^(NSDictionary *response, NSError *error) {
            
            NSLog(@"%@ %@", response, error);
            
        }];
        
        [[RdioSimpleApi shared] call:@"search" parameters:@{
                                                            @"query":@"get lucky",
                                                            @"types":@"Track"
                                                            } block:^(NSDictionary *response, NSError *error) {
                                                                //...
                                                                NSLog(@"%@ %@", response, error);
                                                            }];
        
        
    }];
    
  }

@end
