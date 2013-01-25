//
//  DAImageCache.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAImageCache.h"
#import "DAImage.h"


static DAImageCache *sharedCache = nil;

@interface DAImageCache (private) <DAImageDelegate>
@end
	
@implementation DAImageCache

@synthesize maxCacheEntries;
@synthesize maxCacheMemory;
@synthesize curCacheMemory;

+ (DAImageCache*) sharedCache
{
	if (sharedCache == nil) {
		sharedCache = [[DAImageCache alloc] init];
	}
	return sharedCache;
}

- (void) flushCache:(NSNotification*)notification
{
	[self flushCache];
}

- (id) init
{
	if ((self = [super init]) != nil) {
		maxCacheEntries = 50;
		maxCacheMemory = 0x1400000; // 20Mb
		curCacheMemory = 0;
		cache = [[NSMutableDictionary alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(flushCache:)
													 name:UIApplicationDidReceiveMemoryWarningNotification
												   object:nil];
	}
	return self;
}

- (void) flushCache
{
	for (NSString* key in [cache allKeys]) {
		DAImage *daImage = (DAImage*)[cache objectForKey:key];
		if (daImage.loading == NO) {
			curCacheMemory -= daImage.memoryUsage;
			[cache removeObjectForKey:key];
		}
	}
}

- (void) flushCacheOldest
{
	DAImage *oldestDaImage = nil;
	NSString *oldestKey;
	NSTimeInterval oldest = 0.0f;
	for (NSString* key in [cache allKeys]) {
		DAImage *daImage = (DAImage*)[cache objectForKey:key];
		if (((oldest == 0.0f) || (daImage.lastAccess < oldest)) && (daImage.loading == NO)) {
			oldest = daImage.lastAccess;
			oldestDaImage = daImage;
			oldestKey = key;
		}
	}
	if (oldestDaImage != nil) {
		curCacheMemory -= oldestDaImage.memoryUsage;
		[cache removeObjectForKey:oldestKey];
	}
}

- (UIImage*) imageFromFile:(NSString*)file
{
	return [self imageFromURL:[NSString stringWithFormat:@"bundle://%@", file]];
}

- (UIImage*) imageFromURL:(NSString*)url
{
	DAImage *daImage = [cache objectForKey:url];
	if (daImage != nil) {
		daImage.lastAccess = [NSDate timeIntervalSinceReferenceDate];
		if (daImage.image != nil) {
			return daImage.image;
		}
		daImage.loadingCount++;
		if (!daImage.loading) {
			[daImage startLoad];
		}
		return nil;
	}
	if (([cache count] > maxCacheEntries) || (curCacheMemory > maxCacheMemory)) {
		[self flushCacheOldest];
	}
	daImage = [[DAImage alloc] initWithUrl:url];
	if (daImage != nil) {
		daImage.delegate = self;
		[daImage startLoad];
		[cache setObject:daImage forKey:url];
	}
	return nil;
}

- (void) cancelImage:(NSString*)fileOrUrl
{
	DAImage *daImage = [cache objectForKey:fileOrUrl];
	if (daImage != nil) {
		if (daImage.loadingCount > 0) {
			daImage.loadingCount--;
		}
		if (daImage.loadingCount == 0) {
			if (daImage.loading) {
				[daImage cancelLoad];
			}
		}
	}
}


#pragma mark - DAImageDelegate

- (void) finishedLoading:(DAImage*)daImage
{
	curCacheMemory += daImage.memoryUsage;
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:daImage.name, @"name", daImage.image, @"image", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDAImageCache_ImageLoaded object:self userInfo:dict];
}

- (void) failedLoading:(DAImage*)daImage
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:daImage.name, @"name", daImage.image, @"image", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDAImageCache_ImageLoadFailed object:self userInfo:dict];
}

@end
