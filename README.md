
#RdioSimpleApi for Mac Apps

A simple Rdio Web Service API Objective-C wrapper, for Mac OS X Apps.


## Usage

App authorization happens via Safari. Once authorization is granted, Safari reopens the app using a custom URL scheme (e.g. RdioSimpleApiExample://). You can setup the App to handle such URL scheme by putting the following key in the app Info plist:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
            <key>CFBundleURLName</key>
            <string>Example Rdio Login</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>RdioSimpleApiExample</string>
            </array>
        </dict>
	</array>
```
 

```objective-c
#include <RdioSimpleApi/RdioSimpleApi.h>
... 	
 	[[RdioSimpleApi shared] setupWithKey:@"<YOUR APP's RDIO KEY HERE>" andSecret:@"<YOUR APP SECRET HERE>"];
    
    //Opens a Safari window that asks to connect the app to Rdio. Once authorization is granted, Safari reopens the app using the URL scheme RdioSimpleApiExample://.
    [[RdioSimpleApi shared] authenticateInBrowserWithURLScheme:@"RdioSimpleApiExample" block:^(RdioSimpleApi *api, NSError *error) {
        	[[RdioSimpleApi shared] me:^(NSDictionary *response, NSError *error) {
        		//...
    		}];
    
    	[[RdioSimpleApi shared] call:@"search" parameters:@{
                                                        @"query":@"get lucky",
                                                        @"types":@"Track"
                                                        } block:^(NSDictionary *response, NSError *error) {
        //...
    	}];

    }];
    
```

[Rdio Web Service API reference](Calls http://www.rdio.com/developers/docs/web-service/index/)


##

## Setting up your project


1. Drag RdioSimpleApi.xcodeproj to the top of the tree of your project.
![1](https://github.com/redsh/RdioSimpleApi/raw/master/Doc/add_proj.png)

2. Add the framework to your App's 'Target dependencies'.
![1](https://github.com/redsh/RdioSimpleApi/raw/master/Doc/add_dep.png)

3. Add the framework to your App's 'Linked Frameworks and Libraries'.
![1](https://github.com/redsh/RdioSimpleApi/raw/master/Doc/add_link.png)
 
4. Drag the framework from 'Linked Frameworks and Libraries' and drop it the 'Frameworks' folder of your App project tree.
![1](https://github.com/redsh/RdioSimpleApi/raw/master/Doc/drag_link.png)

## Acknowledgements

Uses:

- AFNetworking, Copyright (c) 2011 Gowalla (http://gowalla.com/)

- AFOAuth1Client.m Copyright (c) 2011 Mattt Thompson (http://mattt.me/)

- AFOAuth2Client.h Copyright (c) 2012 Mattt Thompson (http://mattt.me/)

- JCSSheetController Created by Abizer Nasir on 19/02/11, Based on SDSheetController by Steven Degutis https://github.com/sdegutis/SDSheetController

- NSData+Base64.h Copyright 2009 Matt Gallagher.

Wrapper developed for the 'Enter the Dragon' demo at musichackday 2013 Boston, authors are not affiliated with Rdio.

