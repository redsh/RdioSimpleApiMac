//
//  RdioSimpleApiWebView.h
//  RdioSimpleApi
//
//  Created by Francesco Rossi on 11/21/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface RdioSimpleApiPlayerView : WebView

- (void)loadPlayerFromURL:(NSString*)url;
- (void)loadPlayerFromURL:(NSString*)url askingLoginWithCallbackURLScheme:(NSString*)urlScheme;

- (void)play:(NSString*)track_id fromPosition:(double)positionInSeconds;
- (void)play:(NSString*)track_id;

- (void)play;
- (void)pause;
- (void)playOrPause;

- (void)seek:(double)positionInSeconds;

@property(nonatomic,copy) void(^blockRdioReady)(RdioSimpleApiPlayerView* v, NSError* err);

@property(nonatomic,copy) void(^blockSongInfo)(RdioSimpleApiPlayerView* v, NSString* artist, NSString* title, NSString* iconURL);
@property(nonatomic,copy) void(^blockPlayStateChanged)(RdioSimpleApiPlayerView* v, int playStatus);
@property(nonatomic,copy) void(^blockPositionChanged)(RdioSimpleApiPlayerView* v, double position, double duration);

- (void)setPlayToken:(NSString*)pt;

@property(nonatomic,assign)BOOL ready;
- (void)doWhenReady:(void(^)())block;
- (void)reload;


@end
