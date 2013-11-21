//
//  RdioSimpleApiWebView.m
//  RdioSimpleApi
//
//  Created by Francesco Rossi on 11/21/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "RdioSimpleApiPlayerView.h"
#import "RdioSimpleApi.h"

@interface RdioSimpleApiPlayerView ()
{
    NSString* playToken;
}
@end

@implementation RdioSimpleApiPlayerView

// API
- (void)loadPlayerFromURL:(NSString *)url askingLoginWithCallbackURLScheme:(NSString*)urlScheme
{
    [[RdioSimpleApi shared] authenticateInBrowserWithURLScheme:urlScheme block:^(RdioSimpleApi *api, NSError *error) {
        [self loadPlayerFromURL:url];
    }];
}

- (void)loadPlayerFromURL:(NSString*)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSLog(@"host %@",request.URL.host);
    
    [[RdioSimpleApi shared] call:@"getPlaybackToken" parameters:@{@"domain":request.URL.host} block:^(NSDictionary *response, NSError *error) {
        
        NSLog(@"%@ %@",response,error);
        playToken = response[@"result"];
        [[self mainFrame] loadRequest:request];
        
    }];
    //_webView.UIDelegate = self;
    self.frameLoadDelegate = self;
}

- (void)play:(NSString*)track_id fromPosition:(double)positionInSeconds;
{
    NSString* js_play = [NSString stringWithFormat:@"play_resource(\"%@\",%lf);",track_id,positionInSeconds];
    [self runjs:js_play];
}

- (void)play:(NSString*)track_id;
{
    [self play:track_id fromPosition:-1];
}

- (void)play;
{
    [self runjs:@"play();"];
}

- (void)pause;
{
    [self runjs:@"pause();"];
}

- (void)playOrPause;
{
    [self runjs:@"playpause();"];
}

- (void)seek:(double)positionInSeconds;
{
    [self runjs:[NSString stringWithFormat:@"seek(%lf);",positionInSeconds]];
}

- (void)setPlayToken:(NSString*)pt
{
    NSString* js = [NSString stringWithFormat:@"set_play_token(\"%@\");",pt];
    [self runjs:js];
}

//WebView delegate

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
	//NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    
    
    [self setPlayToken:playToken];
    
    NSScrollView *mainScrollView = webView.mainFrame.frameView.documentView.enclosingScrollView;
    [mainScrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    [mainScrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    
    /* here we'll add our object to the window object as an object named
     'console'.  We can use this object in JavaScript by referencing the 'console'
     property of the 'window' object.   */
    [webView.windowScriptObject setValue:self forKey:@"nativo"];
    
    if(self.blockLoadHTML)
    {
        self.blockLoadHTML(self, nil);
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    if(self.blockLoadHTML)
    {
        self.blockLoadHTML(self, error);
    }
}

// JS interface

- (void)setPlayState:(int)ps
{
    if(self.blockPlayStateChanged)
    {
        self.blockPlayStateChanged(self,ps);
    }
}
- (void)setProgress:(double)progress andDuration:(double)duration
{
    if(self.blockPositionChanged)
    {
        self.blockPositionChanged(self,progress, duration);
    }
}

- (void)setTrack:(NSString*)tr andArtist:(NSString*)art andIcon:(NSString*)icon
{
    if(self.blockSongInfo)
    {
        self.blockSongInfo(self,art,tr,icon);
    }
}


- (void)runjs:(NSString*)js
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString* resp = [self stringByEvaluatingJavaScriptFromString:js];
        NSLog(@"js %@ '%@'",js,resp);
        
    });
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
	//NSLog(@"%@ received %@ for '%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector));
    if (selector == @selector(setProgress:andDuration:)
        || selector == @selector(setPlayState:)
        || selector == @selector(setTrack:andArtist:andIcon:)
        ) {
        return NO;
    }
    return YES;
}
+ (NSString *) webScriptNameForSelector:(SEL)sel {
	//NSLog(@"%@ received %@ with sel='%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(sel));
    if (sel == @selector(setProgress:andDuration:)) {
		return @"setProgress_andDuration_";
    } else if(sel == @selector(setPlayState:)){
        return @"setPlayState_";
    } else if(sel == @selector(setTrack:andArtist:andIcon:)){
        return @"setTrack_andArtist_andIcon_";
	} else {
		return nil;
	}
}
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
	/*NSLog(@"%@ received %@ for '%s'", self, NSStringFromSelector(_cmd), property);
     if (strcmp(property, "sharedValue") == 0) {
     return NO;
     }*/
    return YES;
}


@end
