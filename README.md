Hydra
============

Hydra's aim is to allow the developer to focus on the important implementation, without having to focus on complex things such as: Background tasks, asynchrony, and so on..
All you need to do is to register your tasks to Hydra framework, and Hydra framework will excute your task in the background thread, finally your callback handler is called by Hydra framework when your task is done.

# Installation

You can download the latest framework files from our Release page.
Hydra also available through CocoaPods. To install it simply add the following line to your Podfile.
pod ‘Hydra’

# Setup

At least, one `HYWorker` module is required.
You can make worker module by subclass from `HYworker`.

```objective-c
@interface CommonWorker : HYWorker
```

Add worker to Hydra and start. It’s all.

```objective-c
[[Hydra defaultHydra] addWorker:[[CommonWorker alloc] init]];
[[Hydra defaultHydra] startAllWorkers];
```

# Executor

Most of your business logic will be in `HYExecutor` class.
You can make executor module by subclass from `HYExecutor`.

```objective-c
@interface SampleExecutor : HYExecutor
```

Following code shows how to set your business logic under `HYExecutor` class.

```objective-c
- (NSString *)name
{
   return SampleExecutorName;
}

- (BOOL)calledExecutingWithQuery:(id)anQuery
{
   // get parameter values
   NSInteger a = [[anQuery parameterForKey:@“a”] integerValue];
   NSInteger b = [[anQuery parameterForKey:@“b”] integerValue];

   // prepare result
   HYResult *result = [HYResult resultWithName:self.name];
   [result setParameter:[NSNumber numberWithInteger:a+b] forKey:@“sum”];

   // stored result will notify by result name
   [self storeResult:result];

   return YES;
}
```

Make query and push to `Hydra`.

```objective-c
HYQuery *query = [HYQuery queryWithWorkerName:CommonWorker executorName:SampleExecutorName];
[query setParameter:[NSNumber numberWithInteger:1] forKey:@“a”];
[query setParameter:[NSNumber numberWithInteger:2] forKey:@“b”];
[[Hydra defaultHydra] pushQuery:query];
```

Register callback handler to get the result of your task.

```objective-c
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commonWorkerNotification:) name:CommonWorkerName object:nil];
```

```objective-c
- (void)commonWorkerNotification:(NSNotification *)notification
{
   NSDictionary *userInfo = [notification userInfo];
   HYResult *result = [userInfo objectForKey:SampleExecutorName];
   if( result != nil ) {
      NSInteger sum = [[result parameterForKey:@“sum”] integerValue];
      NSLog( @“sum is %d”, sum );
   }
}
```

# Manager

A helper class to centralize a set of relative excutors.
You can make manager class by subclass from `HYManager`.

```objective-c
@interface SampleManager : HYManager
```

```objective-c
- (void)requestSumOfA:(NSInteger)a andB:(NSInteger)b
{
   HYQuery *query = [self queryForExecutorName:SampleExecutorName];
   [query setParameter:[NSNumber numberWithInteger:a] forKey:@“a”];
   [query setParameter:[NSNumber numberWithInteger:b] forKey:@“b”];
   [[Hydra defaultHydra] pushQuery:query];
}
```

```objective-c
[[SampleManager defaultManager] requestSumOfA:1 andB:2];
```

Following example shows how to simply add notification callback handler.

```objective-c
[self registExecutor:[[SampleExecutor alloc] init] withWorkerName:SampleWorkerName action:@selector(sampleExecutorHandlerWithResult:)];
```

```objective-c
- (NSMutableDictionary *)sampleExecutorHandlerWithResult:(HYResult *)result
{
   NSInteger sum = [[result parameterForKey:@“sum”] integerValue];
   NSLog( @“sum is %d”, sum );
   return nil;
}
```

Also, `HYManager` is able to send a notification by its own name.

```objective-c
- (NSString *)name
{
   return SampleManagerNotification;
}

- (NSMutableDictionary *)sampleExecutorHandlerWithResult:(HYResult *)result
{
   NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
   NSNumber *sum = [result parameterForKey:@“sum”];
   if( sum != nil ) {
      [paramDict setObject:sum forKey:SampleManagerNotifyParameterKeySum];
   }
   if( [paramDict count] == 0 ) {
      return nil;
   }
   // ‘paramDict’ will be ‘userInfo’ of notification ’SampleManagerNotification’.
   return paramDict;
}
```

# AsyncTask

You can also perform additional tasks in parallel, using `AsyncTask` class. So it allows `HYExecutor' to do something else immediately after calling `bindAsyncTask:` method to excute 'AsyncTask'. 

`calledExecutingWithQuery' can be called by `AsyncTask` when it's job has been done.
For that reason, you should know that your 'AsyncTask` class have already done it's job or not by checking the `anQuery` parameter. 
The following code shows that how to set this `anQuery` parameter.

```objective-c
- (BOOL)calledExecutingWithQuery:(id)anQuery
{
   // AsyncTask hasn't done it's job yet.
   if( [[anQuery parameterForKey:SampleExecutorParameterKeyCloseQueryCall] boolValue] == NO ) {
      [anQuery setParameter:@“Y” forKey:SampleExecutorParameterKeyCloseQueryCall];
      SampleAsyncTask *sampleAsyncTask = [[SampleAsyncTask alloc] initWithCloseQuery:anQuery];
      [self bindAsyncTask:sampleAsyncTask];
   // AsyncTask has done it's job yet
   } else {
      NSLog( @“async task done” );
   }

   return YES;
}
```

# TrackingResultSet

`TrackingResultSet` is convenient when you want to track all of registered tasks.
Bellow are the list of when you can get notifications.

1. When all of reigstered tasks have done after these are initilized.
2. When all of reigstered tasks have done after case (1).

```objective-c
HYTrackingResultSet *trackingResultSet = [[HYTrackingResultSet alloc] initWithName:kTrackingResultNameForBooAndFooAllUpdated];
[trackingResultSet setResultNamesFromArray:[NSArray arrayWithObjects:BooExecutorName, FooExecutorName, nil]];
[[Hydra defaultHydra] setTrackingResultSet:trackingResultSet];
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(booAndFooAllUpdated:) name:kTrackingResultNameForBooAndFooAllUpdated object:nil];
```

# Migrator

Your app may be updated many times.
Sometimes, your users need to update their local data to the latest version of data.
You can make this migration module to manage it easily by subclass from `HYMigrator`.

```objective-c
@interface SampleMigrator : HYMigrator
```

```objective-c
- (BOOL)doInitialing
{
   // do something when first initialing task at once
   return YES;
}

- (NSUInteger)suggestedMigrationNumber
{
   // set last version number of migration to 5 for example.
   return 5;
}

- (BOOL)isSomethingToDoForMigrationNumber:(NSUInteger)migrationNumber
{
   // check migration number and do some task for given migration number.
   // if something to do for given migration number then return YES, or if not return NO.
   return YES;
}

- (BOOL)doMigrationForNumber:(NSUInteger)migrationNumber
{
   // if you return YES at method 'isSomethingToDoForMigrationNumber:' for given number then,
   // this method called for do migration task.
   // implement your migration code for given number here.
   return YES;
}
```

```objective-c
SampleMigrator *migrator = [[SampleMigrator alloc] init];
[[Hydra defaultHydra] doMigration:migrator waitUntilDone:NO];
```

# License

MIT License, where applicable. http://en.wikipedia.org/wiki/MIT_License
