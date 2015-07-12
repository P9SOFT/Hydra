//
//  SampleAsyncTask.m
//  Sample03_UsingAsyncTask
//
//  Created by Tae Hyun, Na on 2015. 2. 20..
//  Copyright (c) 2015년 TeamP9. All rights reserved.
//
//  Licensed under the MIT license.

#import "SampleAsyncTask.h"

@implementation SampleAsyncTask

- (NSString *) brief
{
	return @"Sample asyncTask";
}

- (BOOL) didBind
{
	NSMutableURLRequest	*request;
	NSString			*urlString;
	
	// get parameter
	if( (urlString = [self parameterForKey:SampleAsyncTaskParameterKeyUrlString]) == nil ) {
		return NO;
	}
	// start asynchronous job
	if( (request = [[NSMutableURLRequest alloc] init]) == nil ) {
		return NO;
	}
	[request setURL:[NSURL URLWithString:urlString]];
	if( (_connection = [[NSURLConnection alloc] initWithRequest: request delegate: self]) == nil ) {
		return NO;
	}
	
	return YES;
}

- (void) willUnbind
{
	// if need someting to cleaning
	if( _connection != nil ) {
		[_connection cancel];
		_connection = nil;
	}
}

- (void) connection:( NSURLConnection *)connection didReceiveData: (NSData *)data
{
	if( _receivedData == nil ) {
		_receivedData = [[NSMutableData alloc] init];
	}
	[_receivedData appendData: data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
	// 'done' must called when asyncTask job done.
	[self done];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
	// check job doing well and set result parameters to closeQuery.
	if( _receivedData != nil ) {
		UIImage *image = [UIImage imageWithData:_receivedData];
		if( image != nil ) {
			[self setParameter:image forKey:SampleAsyncTaskParameterKeyImage];
		}
	}
	// 'done' must called when asyncTask job done.
	[self done];
}

@end
