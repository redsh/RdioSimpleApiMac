//
//  PlayerViewController.m
//  Example
//
//  Created by Francesco Rossi on 11/21/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import "PlayerViewController.h"
#import <RdioSimpleApi/RdioSimpleApiPlayerView.h>

@interface PlayerViewController ()
{
    
}
@property(nonatomic,assign)double songDuration;
@property(nonatomic,strong)RdioSimpleApiPlayerView* playerView;
@end

@implementation PlayerViewController


- (id)initWithPlayerURL:(NSString*)url
{
    self = [super initWithNibName:@"PlayerViewController" bundle:nil];
    if(self)
    {
        _songDuration =1;
        self.playerURL = url;
    }
    return self;
}

- (IBAction)onPlayPause:(id)sender
{
    [_playerView playOrPause];
}

- (IBAction)onSlider:(id)sender
{
    [_playerView seek:self.posSlider.doubleValue/100.*_songDuration];
}

- (void)loadView
{
    [super loadView];
    
    _playerView = [[RdioSimpleApiPlayerView alloc]initWithFrame:_containerView.bounds];
    [_containerView addSubview:_playerView];
    
    [_playerView loadPlayerFromURL:_playerURL];
    
    
    __unsafe_unretained PlayerViewController* ws = self;
    
    [_playerView setBlockLoadHTML:^(RdioSimpleApiPlayerView * v, NSError * err) {
        
#pragma warning check and reload in case of error!
        [ws.playerView play:@"t30545172"];
        
    }];
    
    [_playerView setBlockPlayStateChanged:^(RdioSimpleApiPlayerView * v, int playState) {
        
        if(playState == 0)
        {
            ws.playButton.title = @"Play";
        }
        else
        {
            ws.playButton.title = @"Pause";
        }
        
    }];
    
    [_playerView setBlockPositionChanged:^(RdioSimpleApiPlayerView * v, double position, double duration) {
        
        ws.songDuration = duration;
        ws.posSlider.doubleValue = position/duration*100.;
        
        int ipos = (int)position;
        
        ws.posLabel.stringValue = [NSString stringWithFormat:@"%.2d:%.2d", ipos/60, ipos%60];
    }];
    
    [_playerView setBlockSongInfo:^(RdioSimpleApiPlayerView * v, NSString * artist, NSString * title, NSString *icon) {
        
        [ws.infoLabel setStringValue:[NSString stringWithFormat:@"%@ - %@",artist,title]];
        
    }];
}

@end
