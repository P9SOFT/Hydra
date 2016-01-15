//
//  SampleAsyncTask.h
//  Sample03_UsingAsyncTask
//
//  Created by Tae Hyun Na on 2015. 2. 20.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

#import <UIKit/UIKit.h>
#import <Hydra/Hydra.h>

#define		SampleAsyncTaskParameterKeyUrlString		@"sampleAsyncTaskParameterKeyUrlString"
#define		SampleAsyncTaskParameterKeyImage			@"sampleAsyncTaskParameterKeyImage"

@interface SampleAsyncTask : HYAsyncTask
{
	NSURLConnection			*_connection;
	NSMutableData			*_receivedData;
}

@end
