//
//  PlaygroundView.m
//  Sample02_UsingManager
//
//  Created by Tae Hyun Na on 2015. 2. 17.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "PlaygroundView.h"

@implementation PlaygroundView

@synthesize imageView = _imageView;
@synthesize doButton = _doButton;

- (instancetype)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) != nil ) {
		
		self.backgroundColor = [UIColor lightGrayColor];
		
		if( (_imageView = [[UIImageView alloc] init]) == nil ) {
			return nil;
		}
		
		if( (_doButton = [UIButton buttonWithType:UIButtonTypeRoundedRect]) == nil ) {
			return nil;
		}
		_doButton.backgroundColor = [UIColor whiteColor];
		_doButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[_doButton setTitle:NSLocalizedString(@"Load image", @"") forState:UIControlStateNormal];
        
        if( (_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]) == nil ) {
            return nil;
        }
		
		[self addSubview:_imageView];
		[self addSubview:_doButton];
        [self addSubview:_activityIndicator];
		
	}
	
	return self;
}

- (void)layoutSubviews
{
	CGRect		frame;
	
	frame.size.width = 300.0f;
	frame.size.height = 265.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = 100.0f;
	
	_imageView.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = (_imageView.frame.origin.y+_imageView.frame.size.height+20.0f);
	
	_doButton.frame = frame;
    
    frame.size = _activityIndicator.frame.size;
    frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
    frame.origin.y = _imageView.frame.origin.y + (int)((_imageView.frame.size.height/2.0f)-(frame.size.height/2.0f));
    
    _activityIndicator.frame = frame;
}

@end
