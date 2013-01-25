//
//  DAPhotoViewController.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/7/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAPhotoSet.h"
#import "DAPhotoView.h"
#import "DAThumbViewController.h"


@interface DAPhotoViewController : UIViewController <DAPhotoViewDelegate, DAPhotoViewDataSource, DAThumbViewControllerDelegate>
{

	IBOutlet UIBarButtonItem *seeAllButton;
	IBOutlet UIBarButtonItem *flexSpace;
	IBOutlet UIBarButtonItem *prevButton;
	IBOutlet UIBarButtonItem *playButton;
	IBOutlet UIBarButtonItem *pauseButton;
	IBOutlet UIBarButtonItem *nextButton;
	
	IBOutlet DAPhotoView *photoView;
	IBOutlet UIView *captionBack;
	IBOutlet UILabel *caption;

	NSUInteger currentPhoto;
	NSMutableDictionary *images;
		
	NSTimer *playTimer;

	BOOL barsHidden;
	
	CGFloat minCaptionHeight;
	
}

@property(nonatomic, assign) UIBarStyle barStyle;
@property(nonatomic, retain) UIColor *tintColor;
@property(nonatomic,assign,getter=isTranslucent) BOOL translucent;

@property(nonatomic, retain) UIFont *captionFont;
@property(nonatomic, retain) UIColor *captionColor;

@property(nonatomic,retain) DAPhotoSet *photoSet;

- (IBAction) seeAll:(id)sender;
- (IBAction) prev:(id)sender;
- (IBAction) play:(id)sender;
- (IBAction) pause:(id)sender;
- (IBAction) next:(id)sender;

- (void) flushImages;

- (void) choosePhoto:(NSUInteger)photo;

@end
