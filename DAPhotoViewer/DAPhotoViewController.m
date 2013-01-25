//
//  DAPhotoViewController.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/7/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAPhotoViewController.h"
#import "DAImageCache.h"
#import "DAPhoto.h"


#define CUR_IDX currentPhoto
#define PREV_IDX ((currentPhoto == 0) ? [photoSet count] - 1 : currentPhoto - 1)
#define NEXT_IDX ((currentPhoto + 1) % [photoSet count])


@interface DAPhotoViewController (private)
- (void) updateTitle;
@end


@implementation DAPhotoViewController

// REALLY NEED TO PROVIDE SETTERS FOR THESE, TO UPDATE navigationBar AND toolbar WHEN THEY ARE CHANGED
@synthesize barStyle;
@synthesize tintColor;
@synthesize translucent;

@synthesize photoSet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		barStyle = UIBarStyleBlackTranslucent;
		tintColor = nil;
		translucent = YES;
		currentPhoto = 0;
		images = [[NSMutableDictionary alloc] init];
		playTimer = nil;
		barsHidden = NO;
		self.wantsFullScreenLayout = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(imageLoaded:)
													 name:kDAImageCache_ImageLoaded
												   object:nil];
    }
    return self;
}

- (id) init
{
	NSString* suffix = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? @"iPhone" : @"iPad";
	self = [self initWithNibName:[NSString stringWithFormat:@"DAPhotoViewController-%@", suffix] bundle:nil];
	if (self != nil) {
		minCaptionHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 20.0f : 30.0f;
	}
	return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.rightBarButtonItem = seeAllButton;
	
	[self setToolbarItems:[NSArray arrayWithObjects:flexSpace, prevButton, flexSpace, playButton, flexSpace, nextButton, flexSpace, nil] animated:NO];
	[self.navigationController setToolbarHidden:NO animated:NO];
	
	self.navigationController.navigationBar.barStyle = barStyle;
	self.navigationController.navigationBar.tintColor = tintColor;
	self.navigationController.navigationBar.translucent = translucent;
	
	self.navigationController.toolbar.barStyle = barStyle;
	self.navigationController.toolbar.tintColor = tintColor;
	self.navigationController.toolbar.translucent = translucent;

	[photoView reloadImages];
	
	[self updateTitle];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
	self.navigationController.toolbar.alpha = 1.0f;
}

- (void) viewDidAppear:(BOOL)animated
{
	[photoView didAppear];
	[self updateTitle];
}


#pragma mark - DAPhotoViewController

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
	[self flushImages];
	[photoView reloadImages];
}

- (UIFont*) captionFont
{
	return caption.font;
}

- (void) setCaptionFont:(UIFont*)font
{
	caption.font = font;
	[self updateTitle];
}

- (UIColor*) captionColor
{
	return caption.textColor;
}

- (void) setCaptionColor:(UIColor*)color
{
	caption.textColor = color;
}

- (IBAction) seeAll:(id)sender
{
	DAThumbViewController *thumbViewController = [[DAThumbViewController alloc] init];
	thumbViewController.delegate = self;
	thumbViewController.barStyle = self.barStyle;
	thumbViewController.tintColor = self.tintColor;
	thumbViewController.translucent = self.translucent;
	thumbViewController.photoSet = self.photoSet;
	[self.navigationController pushViewController:thumbViewController animated:YES];
	
	[photoView willDisappear];
}

- (IBAction) prev:(id)sender
{
	[self pause:nil];	
	[photoView prevPage];
}

- (void) playTimerFired:(NSTimer*)timer
{
	[photoView nextPage];
}

- (IBAction) play:(id)sender
{
	if (playTimer == nil) {
		[self setToolbarItems:[NSArray arrayWithObjects:flexSpace, prevButton, flexSpace, pauseButton, flexSpace, nextButton, flexSpace, nil] animated:YES];
		playTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f
													 target:self
												   selector:@selector(playTimerFired:)
												   userInfo:nil
													repeats:YES];
	}
}

- (IBAction) pause:(id)sender
{
	if (playTimer != nil) {
		[self setToolbarItems:[NSArray arrayWithObjects:flexSpace, prevButton, flexSpace, playButton, flexSpace, nextButton, flexSpace, nil] animated:YES];
		[playTimer invalidate];
		playTimer = nil;
	}
}

- (IBAction) next:(id)sender
{
	[self pause:nil];	
	[photoView nextPage];
}

- (void) loadPhotoAtIndex:(NSUInteger)index intoImage:(NSString*)imgIndex
{
	UIImage *image;
	DAPhoto *photo = [photoSet photoAtIndex:index];
	if ([photo.urlSmall compare:photo.urlLarge] == NSOrderedSame) {
		image = [[DAImageCache sharedCache] imageFromURL:photo.urlLarge];
		if (image == nil) {
			[images removeObjectForKey:imgIndex];
		} else {
			[images setObject:image forKey:imgIndex];
		}
		return;
	}
	
	image = [[DAImageCache sharedCache] imageFromURL:photo.urlSmall];
	if (image == nil) {
		[images removeObjectForKey:imgIndex];
	} else {
		[images setObject:image forKey:imgIndex];
		image = [[DAImageCache sharedCache] imageFromURL:photo.urlLarge];
		if (image != nil) {
			[images setObject:image forKey:imgIndex];
		}
		[photoView reloadImages];
	}
}

- (void) handleLoadedImage:(UIImage*)image
				  withName:(NSString*)name
		   forPhotoAtIndex:(NSUInteger)index
				  forImage:(NSString*)imgIndex
{
	DAPhoto *photo = [photoSet photoAtIndex:index];
	if ([photo.urlLarge compare:name] == NSOrderedSame) {
		[images setObject:image forKey:imgIndex];
		[photoView reloadImages];
		return;
	}
	if ([photo.urlSmall compare:name] == NSOrderedSame) {
		if ([images objectForKey:imgIndex] == nil) {
			[images setObject:image forKey:imgIndex];
			image = [[DAImageCache sharedCache] imageFromURL:photo.urlLarge];
			if (image != nil) {
				[images setObject:image forKey:imgIndex];
			}
			[photoView reloadImages];
		}
	}
}

- (void) loadCurImage
{
	[self loadPhotoAtIndex:CUR_IDX intoImage:@"cur"];
}

- (void) loadPrevImage
{
	[self loadPhotoAtIndex:PREV_IDX intoImage:@"prev"];
}

- (void) loadNextImage
{
	[self loadPhotoAtIndex:NEXT_IDX intoImage:@"next"];
}

- (void) imageLoaded:(NSNotification*)notification
{
	NSDictionary *dict = notification.userInfo;
	NSString *name = [dict objectForKey:@"name"];
	UIImage *image = [dict objectForKey:@"image"];
	
	[self handleLoadedImage:image withName:name forPhotoAtIndex:CUR_IDX forImage:@"cur"];
	[self handleLoadedImage:image withName:name forPhotoAtIndex:PREV_IDX forImage:@"prev"];
	[self handleLoadedImage:image withName:name forPhotoAtIndex:NEXT_IDX forImage:@"next"];
}

- (void) flushImages
{
	[images removeAllObjects];
	[self loadCurImage];
	[self loadPrevImage];
	[self loadNextImage];
}

- (void) choosePhoto:(NSUInteger)photo
{
	if (photo >= [photoSet count]) {
		return;
	}
	currentPhoto = photo;
	[self flushImages];
	[photoView reloadImages];
	[self updateTitle];
}

- (void) updateTitle
{
	self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", currentPhoto+1, [photoSet count]];
	DAPhoto *photo = [photoSet photoAtIndex:currentPhoto];
	caption.text = photo.caption;
	
	CGSize constraint = self.view.bounds.size;
	constraint.width -= 20.0f;
	CGSize size = [photo.caption sizeWithFont:self.captionFont constrainedToSize:constraint lineBreakMode:NSLineBreakByWordWrapping];
	if (size.height < minCaptionHeight) {
		size.height = minCaptionHeight;
	} else {
		size.height += 8.0f;
	}
	CGRect frame = caption.frame;
	CGFloat cur_dy = frame.size.height - minCaptionHeight;
	CGFloat new_dy = size.height - minCaptionHeight - cur_dy;
	frame.origin.y -= new_dy;
	frame.size.height = size.height;
	frame.size.width = constraint.width;
	frame.origin.x = 10.0f;
	caption.frame = frame;
	frame.origin.x = 0.0f;
	frame.size.width = self.view.bounds.size.width;
	captionBack.frame = frame;
}


#pragma mark - DAIPhotoViewDelegate

- (void) willPageLeft
{
}

- (void) didPageLeft
{
	if (currentPhoto == 0) {
		currentPhoto = [photoSet count] - 1;
	} else {
		currentPhoto--;
	}
	[self flushImages];
	[self updateTitle];
}

- (void) willPageRight
{
}

- (void) didPageRight
{
	currentPhoto++;
	if (currentPhoto == [photoSet count]) {
		currentPhoto = 0;
	}
	[self flushImages];
	[self updateTitle];
}

- (BOOL) touchDown
{
	if (barsHidden) {
		return NO;
	}
	barsHidden = YES;
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
	self.navigationController.navigationBar.alpha = 0.0f;
	self.navigationController.toolbar.alpha = 0.0f;
	captionBack.alpha = 0.0f;
	caption.alpha = 0.0f;
	[UIView commitAnimations];
	return YES;
}

- (BOOL) touchUp
{
	if (!barsHidden) {
		return NO;
	}
	barsHidden = NO;
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
	self.navigationController.navigationBar.alpha = 1.0f;
	self.navigationController.toolbar.alpha = 1.0f;
	captionBack.alpha = 1.0f;
	caption.alpha = 1.0f;
	[UIView commitAnimations];
	return YES;
}

- (void) hideHud
{
	if (!barsHidden) {
		barsHidden = YES;
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
		self.navigationController.navigationBar.alpha = 0.0f;
		self.navigationController.toolbar.alpha = 0.0f;
		captionBack.alpha = 0.0f;
		caption.alpha = 0.0f;
		[UIView commitAnimations];
	}
}

- (void) showHud
{
	if (barsHidden) {
		barsHidden = NO;
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:UINavigationControllerHideShowBarDuration];
		self.navigationController.navigationBar.alpha = 1.0f;
		self.navigationController.toolbar.alpha = 1.0f;
		captionBack.alpha = 1.0f;
		caption.alpha = 1.0f;
		[UIView commitAnimations];
	}
}

- (void) toggleHud
{
	if (barsHidden) {
		[self showHud];
	} else {
		[self hideHud];
	}
}

- (void) gestureBegan
{
	[self pause:nil];
}

- (void) gestureEnded
{
}


#pragma mark - DAIPhotoViewDataSource

- (UIImage*) currentImageForPhotoView:(UIView*)photoView
{
	return [images objectForKey:@"cur"];
}

- (UIImage*) prevImageForPhotoView:(UIView*)photoView
{
	return [images objectForKey:@"prev"];
}

- (UIImage*) nextImageForPhotoView:(UIView*)photoView
{
	return [images objectForKey:@"next"];
}


#pragma mark - DAIThumbViewControllerDelegate

- (void) thumbSelected:(NSUInteger)thumb
{
	[self choosePhoto:thumb];
	[self.navigationController popViewControllerAnimated:YES];
}

@end
