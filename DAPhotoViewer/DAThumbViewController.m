//
//  DAThumbViewController.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/15/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAThumbViewController.h"
#import "DAImageCache.h"
#import "DAPhoto.h"


@implementation DAThumbViewController

@synthesize delegate;
@synthesize barStyle;
@synthesize tintColor;
@synthesize translucent;
@synthesize photoSet;

- (id) init
{
	self = [super init];
	if (self != nil) {
		barStyle = UIBarStyleBlackTranslucent;
		tintColor = nil;
		translucent = YES;
		images = [[NSMutableDictionary alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(imageLoaded:)
													 name:kDAImageCache_ImageLoaded
												   object:nil];
	}
	return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadView
{
	thumbView = [[DAThumbView alloc] init];
	thumbView.thumbDataSource = self;
	thumbView.thumbDelegate = self;
	self.view = (UIView*)thumbView;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
	self.navigationController.toolbar.alpha = 0.0f;
	[UIView commitAnimations];
}


#pragma mark - DAThumbViewController

- (DAPhotoSet*) photoSet
{
	return photoSet;
}

- (void) setPhotoSet:(DAPhotoSet*)_photoSet
{
	if (_photoSet == photoSet) {
		return;
	}
	photoSet = _photoSet;
	self.navigationItem.title = photoSet.title;
	[self flushImages];
	[thumbView reloadImages];
}

- (void) flushImages
{
	[images removeAllObjects];
}

- (NSString*) smallestPhotoUrl:(NSUInteger)photoNum
{
	if (photoNum > [photoSet count]) {
		return nil;
	}
	DAPhoto *photo = [photoSet photoAtIndex:photoNum];
	if (photo.urlThumb != nil) {
		return photo.urlThumb;
	}
	if (photo.urlSmall != nil) {
		return photo.urlSmall;
	}
	if (photo.urlLarge != nil) {
		return photo.urlLarge;
	}
	return nil;
}

- (UIImage*) loadPhotoAtIndex:(NSUInteger)index
{
	UIImage *image;
	NSString *url = [self smallestPhotoUrl:index];
	if (url == nil) {
		return nil;
	}
	image = [[DAImageCache sharedCache] imageFromURL:url];
	if (image != nil) {
		[images setObject:image forKey:[NSNumber numberWithUnsignedInteger:index]];
	}
	return image;
}

- (void) imageLoaded:(NSNotification*)notification
{
	NSDictionary *dict = notification.userInfo;
	NSString *name = [dict objectForKey:@"name"];
	UIImage *image = [dict objectForKey:@"image"];
	
	for (NSUInteger index = 0; index < [photoSet count]; index++) {
		if ([[self smallestPhotoUrl:index] compare:name] == NSOrderedSame) {
			[images setObject:image forKey:[NSNumber numberWithUnsignedInteger:index]];
			[thumbView imageLoaded:image forIndex:index];
		}
	}
}


#pragma mark - DAThumbViewDelegate

- (void) thumbSelected:(NSUInteger)thumb
{
	[delegate thumbSelected:thumb];
}


#pragma mark - DAThumbViewDataSource

- (NSUInteger) numPhotosForThumbView:(DAThumbView*)tv
{
	return [photoSet count];
}

- (UIImage*) imageForThumbView:(DAThumbView*)tv forIndex:(NSUInteger)index
{
	return [self loadPhotoAtIndex:index];
}

@end
