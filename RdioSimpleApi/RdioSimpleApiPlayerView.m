//
//  RdioSimpleApiWebView.m
//  RdioSimpleApi
//
//  Created by Francesco Rossi on 11/21/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "RdioSimpleApiPlayerView.h"
#import "RdioSimpleApi.h"
@class WebScriptCallFrame;

@interface RdioSimpleApiPlayerView ()
{
    NSString* playToken;
    NSString* playerURL;
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
    playerURL = url;
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSLog(@"host %@",request.URL.host);
    
    [[RdioSimpleApi shared] call:@"getPlaybackToken" parameters:@{@"domain":request.URL.host} block:^(NSDictionary *response, NSError *error) {
        
        playToken = response[@"result"];
        NSLog(@"%@ %@ %@",response,error,playToken);
        
        [[self mainFrame] loadRequest:request];
        
    }];
    self.frameLoadDelegate = self;
    
}

- (void)reload
{
    [self loadPlayerFromURL:playerURL];
}

- (void)play:(NSString*)track_id fromPosition:(double)positionInSeconds;
{
    NSString* js_play = [NSString stringWithFormat:@"play_resource(\"%@\",%lf);",track_id,positionInSeconds];
    [self doWhenReady:^{
        [self runjs:js_play];
    }];
}

- (void)play:(NSString*)track_id;
{
    [self play:track_id fromPosition:-1];
}

- (void)play;
{
    [self doWhenReady:^{
        [self runjs:@"play();"];
    }];
}

- (void)pause;
{
    [self doWhenReady:^{
        [self runjs:@"pause();"];
    }];
}

- (void)playOrPause;
{
    [self doWhenReady:^{
        [self runjs:@"playpause();"];
    }];
}

- (void)seek:(double)positionInSeconds;
{
    [self doWhenReady:^{
        [self runjs:[NSString stringWithFormat:@"seek(%lf);",positionInSeconds]];
    }];
}

- (void)setPlayToken:(NSString*)pt
{
    NSString* js = [NSString stringWithFormat:@"set_play_token(\"%@\");",pt];
    [self runjs:js];
}

#pragma mark webview delegate

-(void)webViewOnError:(int)err
{
    NSLog(@"WEBVIEW exception in %d", err);
    [self reload];
}

- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)frame {
	//NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    
    
    
    
    NSScrollView *mainScrollView = webView.mainFrame.frameView.documentView.enclosingScrollView;
    [mainScrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    [mainScrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    
    /* here we'll add our object to the window object as an object named
     'console'.  We can use this object in JavaScript by referencing the 'console'
     property of the 'window' object.   */
    [webView.windowScriptObject setValue:self forKey:@"nativo"];
    
    
    [self setPlayToken:playToken];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    self.ready = FALSE;
    
    if(self.blockRdioReady)
    {
        self.blockRdioReady(self, error);
    }
    
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self reload];
    });
}


#pragma mark ready


// JS interface
- (void)rdioReady:(int)rd
{
    self.ready = TRUE;
    
    if(self.blockRdioReady)
    {
        self.blockRdioReady(self, nil);
    }
}

- (void)doWhenReady:(void(^)())block t0:(double)t0 reloaded:(BOOL)reloaded
{
    double t = [NSDate timeIntervalSinceReferenceDate];
    //self.ready = TRUE;
    
    if(self.ready)
    {
        block();
    }
    else if(t - t0 < 60*10) //10 min timeout
    {
        if(t -t0 > 60*2) //reload after 2 minutes and retry later
        {
            [self reload];
            reloaded = TRUE;
        }
        NSLog(@"waiting ready");
        double delayInSeconds = 0.05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self doWhenReady:block t0:t0 reloaded:reloaded];
            
        });
    }
}

- (void)doWhenReady:(void(^)())block
{
    [self doWhenReady:block t0:[NSDate timeIntervalSinceReferenceDate] reloaded:FALSE];
}

#pragma mark api

- (void)setPlayState:(int)ps
{
    if(self.blockPlayStateChanged)
    {
        self.blockPlayStateChanged(self,ps);
        NSLog(@"playstate %d",ps);
    }
}
- (void)setProgress:(double)progress andDuration:(double)duration
{
    //NSLog(@"%f %f",progress,duration);
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
        || selector == @selector(rdioReady:)
        || selector == @selector(webViewOnError:)
        
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
    } else if(sel == @selector(rdioReady:)){
        return @"rdioReady_";
    } else if(sel == @selector(webViewOnError:)){
        return @"webViewOnError_";
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
