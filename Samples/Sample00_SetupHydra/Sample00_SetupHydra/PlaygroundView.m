//
//  PlaygroundView.m
//  Sample00_SetupHydra
//
//  Created by Tae Hyun Na on 2015. 2. 17.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "PlaygroundView.h"

@implementation PlaygroundView

@synthesize titleLabel = _titleLabel;

- (instancetype)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) != nil ) {
		self.backgroundColor = [UIColor lightGrayColor];
		if( (_titleLabel = [[UILabel alloc] init]) == nil ) {
			return nil;
		}
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textColor = [UIColor blackColor];
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
		_titleLabel.numberOfLines = 1;
		_titleLabel.text = @"Hello, Hydra!";
		[self addSubview:_titleLabel];
	}
	
	return self;
}

- (void)layoutSubviews
{
	CGRect		frame;
	
	frame.size.width = 300.0f;
	frame.size.height = 20.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = (int)((self.bounds.size.height/2.0f)-(frame.size.height/2.0f));
	
	_titleLabel.frame = frame;
}

@end
