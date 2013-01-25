//
//  DAPhotoView.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAPhotoView.h"
#import <QuartzCore/QuartzCore.h>
#import "DAImageCache.h"
#import <math.h>


// kPageSpacing is the space between the left edge of mainLayer and the right edge of leftLayer, and between the
// right edge of mainLayer and the left edge of rightLayer.
static const CGFloat kPageSpacing = 20.0f;

// kPageChangeThreshold is the amount of the leftLayer or rightLayer that must be visible during a pinch/pan for
// a page change to occur
static const CGFloat kPageChangeThreshold = 10.0f;

// kMinScale is the minimum scale size which pinching the image.  However, if the user pinches below a scale of 1.0f,
// the scale will snap back to 1.0f when the user releases the pinch
static const CGFloat kMinScale = 0.8f;

// kMaxScale is the maximum scale size after zooming the image.  If the user pinches above this value, the scale
// will snap back to this value when the user releases the pinch.  During the pinch, the scale can be zoomed up
// to kMaxPinchScale
static const CGFloat kMaxScale = 4.0f;
static const CGFloat kMaxPinchScale = 20.0f;


@interface DAPhotoView ()
{
	UIImage* _sourceImage;
}
- (CGSize) calculateImageAspectSize:(CGSize)size;
- (CGAffineTransform) getCurLayerTransform:(CALayer*)l;
- (void) handlePinch:(UIPinchGestureRecognizer *)pinch;
- (void) handlePan:(UIPanGestureRecognizer *)pan;
@end


@implementation DAPhotoView

@synthesize delegate;
@synthesize dataSource;

- (void) initialize
{
	gScale = 1.0f;
	gDelta = CGPointMake(0.0f, 0.0f);
	gestureState = UIGestureRecognizerStatePossible;
	gesturesActive = 0;
	gestureTimer = nil;
	
	mainImageSize = CGSizeZero;
	leftImageSize = CGSizeZero;
	rightImageSize = CGSizeZero;
	_sourceImage = nil;

	mainImageAspectSize = [self calculateImageAspectSize:mainImageSize];
	leftImageAspectSize = [self calculateImageAspectSize:leftImageSize];
	rightImageAspectSize = [self calculateImageAspectSize:rightImageSize];
	
	pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	pinchGR.delegate = self;
	[self addGestureRecognizer:pinchGR];

	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	pan.delegate = self;
	[self addGestureRecognizer:pan];
}

- (void) setupLayers
{
	self.layer.backgroundColor = [UIColor blackColor].CGColor;

	mainLayer = [[CALayer alloc] init];
	mainLayer.backgroundColor = [UIColor clearColor].CGColor;
	mainLayer.contentsGravity = kCAGravityResizeAspect;
	[self.layer addSublayer:mainLayer];
	
	leftLayer = [[CALayer alloc] init];
	leftLayer.backgroundColor = [UIColor clearColor].CGColor;
	leftLayer.contentsGravity = kCAGravityResizeAspect;
	
	rightLayer = [[CALayer alloc] init];
	rightLayer.backgroundColor = [UIColor clearColor].CGColor;
	rightLayer.contentsGravity = kCAGravityResizeAspect;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
		[self setupLayers];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self initialize];
		[self setupLayers];
    }
    return self;
}

- (void) layoutSubviews
{
	mainImageAspectSize = [self calculateImageAspectSize:mainImageSize];
	leftImageAspectSize = [self calculateImageAspectSize:leftImageSize];
	rightImageAspectSize = [self calculateImageAspectSize:rightImageSize];

	mainLayer.position = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
	mainLayer.bounds = self.bounds;
	
	leftLayer.position = CGPointMake((-self.bounds.size.width / 2.0f) - kPageSpacing, self.bounds.size.height / 2.0f);
	leftLayer.bounds = self.bounds;
	
	rightLayer.position = CGPointMake((self.bounds.size.width * 1.5f) + kPageSpacing, self.bounds.size.height / 2.0f);
	rightLayer.bounds = self.bounds;
}

- (void) willDisappear
{
	[leftLayer removeFromSuperlayer];
	[rightLayer removeFromSuperlayer];
}

- (void) didAppear
{
	[self.layer addSublayer:leftLayer];
	[self.layer addSublayer:rightLayer];
}

- (UIImage*) sourceImage
{
	return _sourceImage;
}

- (void) setSourceImage:(UIImage *)sourceImage
{
	if (sourceImage != _sourceImage) {
		_sourceImage = sourceImage;
		[self reloadImages];
	}
}

- (void) reloadImages
{
	UIImage *image;

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

	if (dataSource != nil) {
		image = [dataSource currentImageForPhotoView:self];
		mainImageSize = (image == nil) ? CGSizeZero : image.size;
		mainLayer.contents = (id)image.CGImage;
		
		if ([(NSObject*)dataSource respondsToSelector:@selector(prevImageForPhotoView:)]) {
			image = [dataSource prevImageForPhotoView:self];
			leftImageSize = (image == nil) ? CGSizeZero : image.size;
			leftLayer.contents = (id)image.CGImage;
		} else {
			leftImageSize = CGSizeZero;
		}
		
		if ([(NSObject*)dataSource respondsToSelector:@selector(nextImageForPhotoView:)]) {
			image = [dataSource nextImageForPhotoView:self];
			rightImageSize = (image == nil) ? CGSizeZero : image.size;
			rightLayer.contents = (id)image.CGImage;
		} else {
			rightImageSize = CGSizeZero;
		}
	} else {
		image = _sourceImage;
		mainImageSize = (image == nil) ? CGSizeZero : image.size;
		mainLayer.contents = (id)image.CGImage;
		leftImageSize = CGSizeZero;
		rightImageSize = CGSizeZero;
	}

	mainImageAspectSize = [self calculateImageAspectSize:mainImageSize];
	leftImageAspectSize = [self calculateImageAspectSize:leftImageSize];
	rightImageAspectSize = [self calculateImageAspectSize:rightImageSize];
	
	[CATransaction commit];
}

- (void) prevPage
{
	if (pagingDirection != 0) {
		return;
	}
	
	pagingDirection = -1;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

	[mainLayer removeAllAnimations];
	[leftLayer removeAllAnimations];
	[rightLayer removeAllAnimations];

	CGFloat vw = self.bounds.size.width;

	// get initial position and target position for leftLayer
	CGAffineTransform transform = [self getCurLayerTransform:leftLayer];
	CGFloat lx1 = (transform.tx < 0.0f) ? 0.0f : transform.tx;
	CGFloat lx2 = vw;
	CATransform3D lt1 = CATransform3DMakeTranslation(lx1, 0.0f, 0.0f);
	CATransform3D lt2 = CATransform3DMakeTranslation(lx2, 0.0f, 0.0f);

	// get initial position and target position for mainLayer
	transform = [self getCurLayerTransform:mainLayer];
	CGFloat ms = transform.a;
	CGFloat mx1 = transform.tx;
	CGFloat mx2 = mx1 + (vw - lx1);
	CGFloat my = transform.ty;
	CATransform3D mt1 = CATransform3DScale(CATransform3DMakeTranslation(mx1, my, 0.0f), ms, ms, 1.0f);
	CATransform3D mt2 = CATransform3DScale(CATransform3DMakeTranslation(mx2, my, 0.0f), ms, ms, 1.0f);

	// get initial position and target position for rightLayer
	transform = [self getCurLayerTransform:rightLayer];
	CGFloat rx1 = transform.tx;
	CGFloat rx2 = rx1 + (vw - lx1);
	CATransform3D rt1 = CATransform3DMakeTranslation(rx1, 0.0f, 0.0f);
	CATransform3D rt2 = CATransform3DMakeTranslation(rx2, 0.0f, 0.0f);

	CABasicAnimation *anim;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:lt1];
	anim.toValue = [NSValue valueWithCATransform3D:lt2];
	anim.duration = 0.2f;
	anim.delegate = self;
	[leftLayer addAnimation:anim forKey:nil];
	leftLayer.transform = lt2;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:mt1];
	anim.toValue = [NSValue valueWithCATransform3D:mt2];
	anim.duration = 0.2f;
	[mainLayer addAnimation:anim forKey:nil];
	mainLayer.transform = mt2;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:rt1];
	anim.toValue = [NSValue valueWithCATransform3D:rt2];
	anim.duration = 0.2f;
	[rightLayer addAnimation:anim forKey:nil];
	rightLayer.transform = rt2;
	
	[CATransaction commit];
}

- (void) nextPage
{
	if (pagingDirection != 0) {
		return;
	}
	
	pagingDirection = 1;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	
	[mainLayer removeAllAnimations];
	[leftLayer removeAllAnimations];
	[rightLayer removeAllAnimations];
	
	CGFloat vw = self.bounds.size.width;
	
	// get initial position and target position for rightLayer
	CGAffineTransform transform = [self getCurLayerTransform:rightLayer];
	CGFloat rx1 = (transform.tx > 0.0f) ? 0.0f : transform.tx;
	CGFloat rx2 = -vw;
	CATransform3D rt1 = CATransform3DMakeTranslation(rx1, 0.0f, 0.0f);
	CATransform3D rt2 = CATransform3DMakeTranslation(rx2, 0.0f, 0.0f);
	
	// get initial position and target position for mainLayer
	transform = [self getCurLayerTransform:mainLayer];
	CGFloat ms = transform.a;
	CGFloat mx1 = transform.tx;
	CGFloat mx2 = mx1 - (vw + rx1);
	CGFloat my = transform.ty;
	CATransform3D mt1 = CATransform3DScale(CATransform3DMakeTranslation(mx1, my, 0.0f), ms, ms, 1.0f);
	CATransform3D mt2 = CATransform3DScale(CATransform3DMakeTranslation(mx2, my, 0.0f), ms, ms, 1.0f);
	
	// get initial position and target position for leftLayer
	transform = [self getCurLayerTransform:leftLayer];
	CGFloat lx1 = transform.tx;
	CGFloat lx2 = lx1 - (vw + lx1);
	CATransform3D lt1 = CATransform3DMakeTranslation(lx1, 0.0f, 0.0f);
	CATransform3D lt2 = CATransform3DMakeTranslation(lx2, 0.0f, 0.0f);
	
	CABasicAnimation *anim;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:rt1];
	anim.toValue = [NSValue valueWithCATransform3D:rt2];
	anim.duration = 0.2f;
	anim.delegate = self;
	[rightLayer addAnimation:anim forKey:nil];
	rightLayer.transform = rt2;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:mt1];
	anim.toValue = [NSValue valueWithCATransform3D:mt2];
	anim.duration = 0.2f;
	[mainLayer addAnimation:anim forKey:nil];
	mainLayer.transform = mt2;
	
	anim = [CABasicAnimation animationWithKeyPath:@"transform"];
	anim.fromValue = [NSValue valueWithCATransform3D:lt1];
	anim.toValue = [NSValue valueWithCATransform3D:lt2];
	anim.duration = 0.2f;
	[leftLayer addAnimation:anim forKey:nil];
	leftLayer.transform = lt2;
	
	[CATransaction commit];
}

// This calculates the actual size of the image as displayed in its layer without any scaling of the layer.
- (CGSize) calculateImageAspectSize:(CGSize)size
{
	if (CGSizeEqualToSize(size, CGSizeZero)) {
		return CGSizeZero;
	}
	
	CGFloat widthAspect = size.width / self.bounds.size.width;
	CGFloat heightAspect = size.height / self.bounds.size.height;
	CGFloat aspect = MAX(widthAspect, heightAspect);
	return CGSizeMake(size.width / aspect, size.height / aspect);
}

// This gets the current transform of a layer, as it is currently displayed on screen
- (CGAffineTransform) getCurLayerTransform:(CALayer*)l;
{
	CALayer *pl = [l presentationLayer];
	if (pl == nil) {
		pl = l;
	}
	return [pl affineTransform];
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	if (flag) {
		if (pagingDirection == -1) {
			if ([(NSObject*)delegate respondsToSelector:@selector(didPageLeft)]) [delegate didPageLeft];
		} else if (pagingDirection == 1) {
			if ([(NSObject*)delegate respondsToSelector:@selector(didPageRight)]) [delegate didPageRight];
		}
		pagingDirection = 0;
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		gScale = 1.0f;
		gDelta = CGPointMake(0.0f, 0.0f);
		gScaleCenter = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
		gestureState = UIGestureRecognizerStatePossible;
		gesturesActive = 0;
		mainLayer.transform = CATransform3DIdentity;
		leftLayer.transform = CATransform3DIdentity;
		rightLayer.transform = CATransform3DIdentity;
		[self reloadImages];
		[CATransaction commit];
	}
}

- (void) gestureTimerExpired:(NSTimer*)timer
{
	// initialScale and initialDelta are the scale and delta values of mainLayer when the gesture began
	static CGFloat initialScale;
	static CGPoint initialDelta;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

	if (gestureState == UIGestureRecognizerStateBegan) {
		if ([(NSObject*)delegate respondsToSelector:@selector(hideHud)]) [delegate hideHud];
		[mainLayer removeAllAnimations];
		[leftLayer removeAllAnimations];
		[rightLayer removeAllAnimations];
		CGAffineTransform transform = [mainLayer affineTransform];
		initialScale = transform.a;
		initialDelta = CGPointMake(transform.tx, transform.ty);
		gScaleCenter.x -= (mainLayer.position.x + transform.tx);
		gScaleCenter.y -= (mainLayer.position.y + transform.ty);
		gScaleCenter.x /= initialScale;
		gScaleCenter.y /= initialScale;
		gestureState = UIGestureRecognizerStateChanged;
		if ([(NSObject*)delegate respondsToSelector:@selector(gestureBegan)]) [delegate gestureBegan];
	}

	// scaleActual is the actual scale value with which mainLayer will be transformed
	CGFloat scaleActual;
	if (gScale < 1.0f) {
		scaleActual = gScale * initialScale;
	} else {
		scaleActual = gScale - 1.0f + initialScale;
	}
	if (scaleActual < 1.0f) {
		// This causes scaling below 1.0f to be 'compressed' so the image doesn't get very small
		scaleActual = kMinScale + (scaleActual * (1.0f - kMinScale));
	} else if (scaleActual > kMaxPinchScale) {
		scaleActual = kMaxPinchScale;
		pinchGR.scale = scaleActual - initialScale + 1.0f;
	}
	
	// Get width and height of view (vw,vh), and width and height of mainLayer image (iw,ih)
	CGFloat vw = self.bounds.size.width;
	CGFloat vh = self.bounds.size.height;
	CGFloat iw = mainImageAspectSize.width;
	CGFloat ih = mainImageAspectSize.height;

	// Calculate center points of view, everything is relative to this
	CGFloat centx = self.bounds.size.width / 2.0f;
	CGFloat centy = self.bounds.size.height / 2.0f;
	
	// Get the relative scale of the effective area of the mainLayer.  If the mainLayer is scaled <= the view bounds,
	// this scale value will be 0.0.  If the mainLayer is scaled > the view bounds, this value with be the difference
	// between 1.0 and the actual scale value, i.e., (scaleActual - 1.0)
	CGFloat curRelScale = (scaleActual <= 1.0f) ? 0.0f : (scaleActual - 1.0f);
	
	// curRelCenterScale is the difference in scale between initialScale and curRelScale.
	CGFloat curRelCenterScale = scaleActual - initialScale;
	CGFloat ctpx = gScaleCenter.x * curRelCenterScale;
	CGFloat ctpy = gScaleCenter.y * curRelCenterScale;
	
	// Calculate current actual position and size, and current effective size, of mainLayer (camx,camy,camw,camh,cemw,cemh)
	// The actual position and size is what is actually currently displayed on screen.  The effective size is the space
	// on screen reserved for the mainLayer.  The left and right layers are pinned to the left and right sides of this
	// effective space.
//	CGFloat camw = vw * scaleActual; NOT USED
//	CGFloat camh = vh * scaleActual; NOT USED
	CGFloat cemw = vw * (curRelScale + 1.0f);
	CGFloat cemh = ih * (curRelScale + 1.0f);
	CGFloat camx = centx + initialDelta.x + gDelta.x - ctpx;//(gScaleCenter.x * curRelCenterScale);
	CGFloat camy;
	if (cemh > vh) {
		camy = centy + initialDelta.y + gDelta.y - ctpy;//(gScaleCenter.y * curRelCenterScale);
		if ((camy - (cemh / 2.0f)) > 0.0f) {
			initialDelta.y -= (camy - (cemh / 2.0f));
			camy = cemh / 2.0f;
		} else if ((camy + (cemh / 2.0f)) < vh) {
			initialDelta.y += (vh - (camy + (cemh / 2.0f)));
			camy = vh - (cemh / 2.0f);
		}
	} else {
		camy = centy;
	}

	// Calculate current position and size of leftLayer (clx,cly,clw,clh) and rightLayer (crx,cry,crw,crh)
	CGFloat clw = leftLayer.bounds.size.width;
//	CGFloat clh = leftLayer.bounds.size.height; NOT USED
	CGFloat clx = camx - (cemw / 2.0f) - (clw / 2.0f) - kPageSpacing;
	CGFloat cly = centy;
	CGFloat crw = rightLayer.bounds.size.width;
//	CGFloat crh = rightLayer.bounds.size.height; NOT USED
	CGFloat crx = camx + (cemw / 2.0f) + (crw / 2.0f) + kPageSpacing;
	CGFloat cry = centy;

	// These are the delta values for the current gesture scale and position
	CGFloat cd_mx = camx - centx;
	CGFloat cd_my = camy - centy;
	CGFloat cd_lx = clx - leftLayer.position.x;
	CGFloat cd_ly = cly - leftLayer.position.y;
	CGFloat cd_rx = crx - rightLayer.position.x;
	CGFloat cd_ry = cry - rightLayer.position.y;
	
	CATransform3D mTransform = CATransform3DScale(CATransform3DMakeTranslation(cd_mx, cd_my, 0.0f), scaleActual, scaleActual, 1.0f);
	CATransform3D lTransform = CATransform3DMakeTranslation(cd_lx, 0.0f, 0.0f);
	CATransform3D rTransform = CATransform3DMakeTranslation(cd_rx, 0.0f, 0.0f);
	
	if ((gestureState == UIGestureRecognizerStateBegan) || (gestureState == UIGestureRecognizerStateChanged)) {
		mainLayer.transform = mTransform;
		leftLayer.transform = lTransform;
		rightLayer.transform = rTransform;
	}

	if ((gestureState == UIGestureRecognizerStateEnded) || (gestureState == UIGestureRecognizerStateCancelled)) {
		BOOL animate;
		CAMediaTimingFunction *timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		NSTimeInterval duration = 0.8f;
		id animDelegate = nil;

		CATransform3D mTransformT = mTransform;
		CATransform3D lTransformT = lTransform;
		CATransform3D rTransformT = rTransform;
		
		// These are the target translation values for the layers
		CGFloat tgt_mx = camx + ctpx;// + (gScaleCenter.x * curRelCenterScale);
		CGFloat tgt_my = camy + ctpy;// + (gScaleCenter.y * curRelCenterScale);
		
		CGFloat scaleTarget = MIN(MAX(1.0f, scaleActual), kMaxScale);
		curRelCenterScale = scaleTarget - initialScale;
		ctpx = (gScaleCenter.x * curRelCenterScale);
		ctpy = (gScaleCenter.y * curRelCenterScale);
		tgt_mx -= ctpx;
		tgt_my -= ctpy;
		
		if ((sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y)) > 200.0f) &&
			(([NSDate timeIntervalSinceReferenceDate] - velocityTimeStamp) < 0.02f)) {
			animate = YES;
			tgt_mx += (velocity.x / 2.0f);
			tgt_my += (velocity.y / 2.0f);
		} else {
			velocity = CGPointZero;
		}

		CGFloat tgt_mw = vw * scaleTarget;
		CGFloat tgt_amw = iw * scaleTarget;
		CGFloat tgt_mh = ih * scaleTarget;
		if (scaleTarget != scaleActual) {
			animate = YES;
			duration = 0.2f;
		}
		if (tgt_mh < vh) {
			tgt_my = centy;
		} else {
			if ((tgt_my - (tgt_mh / 2.0f)) > 0.0f) {
				tgt_my -= (tgt_my - (tgt_mh / 2.0f));
			}
			if ((tgt_my + (tgt_mh / 2.0f)) < vh) {
				tgt_my = vh - (tgt_mh / 2.0f);
			}
		}

		CGFloat wd = (mainImageAspectSize.width * (scaleTarget)) / 2.0f;
		CGFloat tgt_lx = tgt_mx - wd - (clw / 1.0f);
		CGFloat tgt_ly = cly;
		CGFloat tgt_rx = tgt_mx + wd + (crw / 1.0f);
		CGFloat tgt_ry = cry;
		
		if ((leftImageSize.width != 0.0f) && (leftImageSize.height != 0.0f)) {
			if (((tgt_lx + (clw / 2.0f)) > kPageChangeThreshold) && (velocity.x > 0.0f)) {
				tgt_mx = vw + (tgt_mw / 2.0f);
				tgt_lx = vw / 2.0f;
				animate = YES;
				duration = 0.2f;
				timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
				animDelegate = self;
				pagingDirection = -1;
				if ([(NSObject*)delegate respondsToSelector:@selector(willPageLeft)]) [delegate willPageLeft];
			}
		}
		
		if ((rightImageSize.width != 0.0f) && (rightImageSize.height != 0.0f)) {
			if (((tgt_rx - (crw / 2.0f)) < (vw - kPageChangeThreshold)) && (velocity.x < 0.0f)) {
				tgt_mx = - (tgt_mw / 2.0f);
				tgt_rx = vw / 2.0f;
				animate = YES;
				duration = 0.2f;
				timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
				animDelegate = self;
				pagingDirection = 1;
				if ([(NSObject*)delegate respondsToSelector:@selector(willPageRight)]) [delegate willPageRight];
			}
		}
		
		if (pagingDirection == 0) {
			CGFloat mw = (tgt_amw > vw) ? tgt_amw : tgt_mw;
			if ((tgt_mx - (mw / 2.0f)) > 0.0f) {
				tgt_mx = mw / 2.0f;
				tgt_lx = -(clw / 2.0f);
				tgt_rx = vw + (crw / 2.0f);
				animate = YES;
				duration = 0.2f;
			}
			if ((tgt_mx + (mw / 2.0f)) < vw) {
				tgt_mx = vw - (mw / 2.0f);
				tgt_lx = -(clw / 2.0f);
				tgt_rx = vw + (crw / 2.0f);
				animate = YES;
				duration = 0.2f;
			}
		}

		// These are the delta values for the current gesture scale and position
		cd_mx = tgt_mx - centx;
		cd_my = tgt_my - centy;
		cd_lx = tgt_lx - leftLayer.position.x;
		cd_ly = tgt_ly - leftLayer.position.y;
		cd_rx = tgt_rx - rightLayer.position.x;
		cd_ry = tgt_ry - rightLayer.position.y;
		
		if (animate) {
			CABasicAnimation *anim;
			[CATransaction setAnimationTimingFunction:timing];

			mTransformT = CATransform3DScale(CATransform3DMakeTranslation(cd_mx, cd_my, 0.0f), scaleTarget, scaleTarget, 1.0f);
			lTransformT = CATransform3DMakeTranslation(cd_lx, 0.0f, 0.0f);
			rTransformT = CATransform3DMakeTranslation(cd_rx, 0.0f, 0.0f);
			
			anim = [CABasicAnimation animationWithKeyPath:@"transform"];
			anim.duration = duration;
			anim.fromValue = [NSValue valueWithCATransform3D:mTransform];
			anim.toValue = [NSValue valueWithCATransform3D:mTransformT];
			anim.delegate = animDelegate;
			[mainLayer addAnimation:anim forKey:nil];
			mainLayer.transform = mTransformT;
			
			anim = [CABasicAnimation animationWithKeyPath:@"transform"];
			anim.duration = duration;
			anim.fromValue = [NSValue valueWithCATransform3D:lTransform];
			anim.toValue = [NSValue valueWithCATransform3D:lTransformT];
			[leftLayer addAnimation:anim forKey:nil];
			leftLayer.transform = lTransformT;
			
			anim = [CABasicAnimation animationWithKeyPath:@"transform"];
			anim.duration = duration;
			anim.fromValue = [NSValue valueWithCATransform3D:rTransform];
			anim.toValue = [NSValue valueWithCATransform3D:rTransformT];
			[rightLayer addAnimation:anim forKey:nil];
			rightLayer.transform = rTransformT;
		} else {
			mainLayer.transform = mTransform;
			leftLayer.transform = lTransform;
			rightLayer.transform = rTransform;
		}
	}
	
	[CATransaction commit];

	if ((gestureState == UIGestureRecognizerStateEnded) || (gestureState == UIGestureRecognizerStateCancelled)) {
		[gestureTimer invalidate];
		gestureTimer = nil;
		gestureState = UIGestureRecognizerStatePossible;
		pinchGR.scale = 1.0f;
		gScale = 1.0f;
		gDelta = CGPointZero;
		gScaleCenter = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
		if ([(NSObject*)delegate respondsToSelector:@selector(gestureEnded)]) [delegate gestureEnded];
	}
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch
{
	switch (pinch.state) {
		case UIGestureRecognizerStateBegan:
			gesturesActive++;
			gScale = pinch.scale;
			if (gestureState == UIGestureRecognizerStatePossible) {
				gScaleCenter = [pinch locationInView:self];
				gestureState = pinch.state;
				gestureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
																target:self
															  selector:@selector(gestureTimerExpired:)
															  userInfo:nil
															   repeats:YES];
			}
			[self gestureTimerExpired:nil];
			break;
		case UIGestureRecognizerStateChanged:
			gestureState = pinch.state;
			gScale = pinch.scale;
			break;
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
			gScale = pinch.scale;
			gesturesActive--;
			if (gesturesActive == 0) {
				gestureState = pinch.state;
			}
			break;
		default:
			break;
	}
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
	switch (pan.state) {
		case UIGestureRecognizerStateBegan:
			gesturesActive++;
			gDelta = [pan translationInView:self];
			velocity = [pan velocityInView:self];
			velocityTimeStamp = [NSDate timeIntervalSinceReferenceDate];
			if (gestureState == UIGestureRecognizerStatePossible) {
				gScaleCenter = [pan locationInView:self];
				gestureState = pan.state;
				gestureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
																target:self
															  selector:@selector(gestureTimerExpired:)
															  userInfo:nil
															   repeats:YES];
			}
			[self gestureTimerExpired:nil];
			break;
		case UIGestureRecognizerStateChanged:
			gestureState = pan.state;
			gDelta = [pan translationInView:self];
			velocity = [pan velocityInView:self];
			velocityTimeStamp = [NSDate timeIntervalSinceReferenceDate];
			break;
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
			gDelta = [pan translationInView:self];
			velocity = [pan velocityInView:self];
			velocityTimeStamp = [NSDate timeIntervalSinceReferenceDate];
			gesturesActive--;
			if (gesturesActive == 0) {
				gestureState = pan.state;
			}
			break;
		default:
			break;
	}
}

- (void) toggleZoom:(CGPoint)point
{
	[mainLayer removeAllAnimations];
	[leftLayer removeAllAnimations];
	[rightLayer removeAllAnimations];

	CGAffineTransform transform = [self getCurLayerTransform:mainLayer];
	CGFloat zoomTo = 1.0f, dx = 0.0f, dy = 0.0f;
	if (transform.a == 1.0f) {
		zoomTo = kMaxScale;
		dx = (mainLayer.position.x - point.x) * (kMaxScale - 1.0f);
		dy = (mainLayer.position.y - point.y) * (kMaxScale - 1.0f);
	}
	mainLayer.transform = CATransform3DScale(CATransform3DMakeTranslation(dx, dy, 0.0f), zoomTo, zoomTo, 1.0f);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([touches count] > 1) {
		return;
	}
	touchStartTime = [[touches anyObject] timestamp];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([touches count] > 1) {
		return;
	}
	NSUInteger numTaps = [[touches anyObject] tapCount];
	if (numTaps == 1) {
		NSTimeInterval touchTime = [[touches anyObject] timestamp];
		if ((touchTime - touchStartTime) > 0.3f) {
			return;
		}
		if (delegate != nil) {
			if ([(NSObject*)delegate respondsToSelector:@selector(toggleHud)]) {
				[(NSObject*)delegate performSelector:@selector(toggleHud) withObject:nil afterDelay:0.3f];
			}
		} else {
			[self sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
	} else {
		[NSObject cancelPreviousPerformRequestsWithTarget:delegate selector:@selector(toggleHud) object:nil];
		[self toggleZoom:[[touches anyObject] locationInView:self]];
	}
}

@end
