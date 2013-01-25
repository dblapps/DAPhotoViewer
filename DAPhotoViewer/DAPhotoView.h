//
//  DAPhotoView.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol DAPhotoViewDelegate
@optional
- (void) willPageLeft;
- (void) didPageLeft;
- (void) willPageRight;
- (void) didPageRight;
- (BOOL) touchDown;
- (BOOL) touchUp;
- (void) hideHud;
- (void) showHud;
- (void) toggleHud;
- (void) gestureBegan;
- (void) gestureEnded;
@end


@protocol DAPhotoViewDataSource
- (UIImage*) currentImageForPhotoView:(UIView*)photoView;
@optional
- (UIImage*) prevImageForPhotoView:(UIView*)photoView;
- (UIImage*) nextImageForPhotoView:(UIView*)photoView;
@end


@interface DAPhotoView : UIControl <UIGestureRecognizerDelegate>
{
	CALayer *mainLayer;
	CALayer *leftLayer;
	CALayer *rightLayer;
	
	CGSize mainImageSize, mainImageAspectSize;
	CGSize leftImageSize, leftImageAspectSize;
	CGSize rightImageSize, rightImageAspectSize;
	
	UIPinchGestureRecognizer *pinchGR;
	UIGestureRecognizerState gestureState;
	NSUInteger gesturesActive;
	CGFloat gScale;
	CGPoint gScaleCenter;
	CGPoint gDelta;
	CGPoint velocity;
	NSTimeInterval velocityTimeStamp;
	
	NSTimer *gestureTimer;
	
	NSTimeInterval touchStartTime;
	
	NSInteger pagingDirection; // -1 = left, 1 = right
}

@property (assign) id<DAPhotoViewDelegate> delegate;
@property (assign) id<DAPhotoViewDataSource> dataSource;
@property (strong,nonatomic) UIImage* sourceImage;

- (void) willDisappear;
- (void) didAppear;
- (void) reloadImages;
- (void) prevPage;
- (void) nextPage;

@end
