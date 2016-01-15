//
//  PlaygroundView.m
//  Sample04_UsingTrackingResultSet
//
//  Created by Tae Hyun Na on 2012. 3. 10.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import "PlaygroundView.h"

@implementation PlaygroundView

@synthesize logView = _logView;
@synthesize booButton = _booButton;
@synthesize fooButton = _fooButton;

- (id)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) != nil ) {
		
		self.backgroundColor = [UIColor lightGrayColor];
		
		if( (_logView = [[UITextView alloc] init]) == nil ) {
			return nil;
		}
		_logView.backgroundColor = [UIColor whiteColor];
		_logView.editable = NO;
		
		if( (_booButton = [UIButton buttonWithType:UIButtonTypeRoundedRect]) == nil ) {
			return nil;
		}
		_booButton.backgroundColor = [UIColor whiteColor];
		_booButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[_booButton setTitle:NSLocalizedString(@"Boo", @"") forState:UIControlStateNormal];
		
		if( (_fooButton = [UIButton buttonWithType:UIButtonTypeRoundedRect]) == nil ) {
			return nil;
		}
		_fooButton.backgroundColor = [UIColor whiteColor];
		_fooButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		[_fooButton setTitle:NSLocalizedString(@"Foo", @"") forState:UIControlStateNormal];
		
		[self addSubview:_logView];
		[self addSubview:_booButton];
		[self addSubview:_fooButton];
		
	}
	
	return self;
}

- (void)layoutSubviews
{
	CGRect		frame;
	
	frame.size.width = self.bounds.size.width - 20.0f;
	frame.size.height = self.bounds.size.height - 80.0f;
	frame.origin.x = (int)((self.bounds.size.width/2.0f)-(frame.size.width/2.0f));
	frame.origin.y = 30.0f;
	
	_logView.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = 10.0f;
	frame.origin.y = self.bounds.size.height - 10.0f - frame.size.height;
	
	_booButton.frame = frame;
	
	frame.size.width = 100.0f;
	frame.size.height = 30.0f;
	frame.origin.x = self.bounds.size.width - 10.0f - frame.size.width;
	frame.origin.y = self.bounds.size.height - 10.0f - frame.size.height;
	
	_fooButton.frame = frame;
}

@end
