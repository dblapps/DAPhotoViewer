//
//  DAImage.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAImage.h"


@implementation DAImage

@synthesize delegate;
@synthesize name;
@synthesize image;
@synthesize loading;
@synthesize loadingCount;
@synthesize lastAccess;
@synthesize memoryUsage;

- (id) init
{
	if ((self = [super init]) != nil) {
		name = nil;
		url = nil;
		image = nil;
		loading = NO;
		loadingCount = 0;
		urlConnection = nil;
		imageData = nil;
		lastAccess = [NSDate timeIntervalSinceReferenceDate];
		memoryUsage = 0;
	}
	return self;
}

- (id) initWithUrl:(NSString*)_url
{
	if ((self = [self init]) != nil) {
		name = [_url copy];
		NSArray *components = [_url componentsSeparatedByString:@"://"];
		NSString *_file = nil;
		if ([components count] == 1) {
			_file = _url;
		} else {
			NSString *comp1 = [components objectAtIndex:0];
			if ([comp1 compare:@"bundle"] == NSOrderedSame) {
				_file = [_url substringFromIndex:9];
			}
		}
		if (_file != nil) {
			NSString *fullFilenamePath = [[NSBundle mainBundle] pathForResource:_file ofType:@""];
			if (fullFilenamePath == nil) {
				self = nil;
				return nil;
			}
			url = [[NSURL alloc] initFileURLWithPath:fullFilenamePath];
		} else {
			url = [[NSURL alloc] initWithString:_url];
		}
	}
	return self;
}

- (void) dealloc
{
	if (loading) {
		[self cancelLoad];
	}
}

- (void) startLoad
{
	if (loading) {
		return;
	}
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	loading = YES;
}

- (void) cancelLoad
{
	if (!loading) {
		return;
	}
	[urlConnection cancel];
	urlConnection = nil;
	imageData = nil;
	loading = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	imageData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	urlConnection = nil;
	image = [UIImage imageWithData:imageData];
	memoryUsage = imageData.length;
	imageData = nil;
	loading = NO;
	loadingCount = 0;
	if (image == nil) {
		[delegate failedLoading:self];
	} else {
		[delegate finishedLoading:self];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	urlConnection = nil;
	imageData = nil;
	[delegate failedLoading:self];
}

@end
