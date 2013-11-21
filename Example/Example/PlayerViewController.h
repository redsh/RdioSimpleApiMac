//
//  PlayerViewController.h
//  Example
//
//  Created by Francesco Rossi on 11/21/13.
//  Copyright (c) 2013 redsh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlayerViewController : NSViewController

- (id)initWithPlayerURL:(NSString*)url;
@property(nonatomic,strong)NSString* playerURL;

@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSSlider *posSlider;
@property (weak) IBOutlet NSView *containerView;
@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSTextField *posLabel;

@end
