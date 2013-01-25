//
//  DAThumbView.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAThumbView.h"
#import <QuartzCore/QuartzCore.h>


@interface DAThumbView (private)
- (void) calculateLayerSpacing;
@end


@implementation DAThumbView

@synthesize thumbDelegate;
@synthesize thumbDataSource;

- (void) initialize
{
	self.delegate = self;
	self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	thumbLayers = [[NSMutableArray alloc] init];
	contentView = [[UIView alloc] initWithFrame:self.frame];
	[self addSubview:contentView];
	curUpperLeftIndex = 0;
	touchMoved = NO;
	
	[self calculateLayerSpacing];
}

- (void) setupLayers
{
	self.backgroundColor = [UIColor blackColor];
	
	NSUInteger numThumbLayers = MIN(numCols * numRows, [thumbDataSource numPhotosForThumbView:self]);
	for (NSUInteger tn = 0; tn < numThumbLayers; tn++) {
		CALayer *thumbLayer = [[CALayer alloc] init];
		thumbLayer.contentsGravity = kCAGravityResizeAspectFill;
		thumbLayer.masksToBounds = YES;
		[contentView.layer addSublayer:thumbLayer];
		[thumbLayers addObject:thumbLayer];
		UIImage *image = [thumbDataSource imageForThumbView:self forIndex:tn+curUpperLeftIndex];
		if (image != nil) {
			thumbLayer.contents = (id)image.CGImage;
		}
	}
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
	[self calculateLayerSpacing];

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

	NSUInteger np = [thumbDataSource numPhotosForThumbView:self];

	NSUInteger numThumbLayers = MIN(numCols * numRows, np);
	for (NSUInteger tn = [thumbLayers count]; tn < numThumbLayers; tn++) {
		CALayer *thumbLayer = [[CALayer alloc] init];
		thumbLayer.contentsGravity = kCAGravityResizeAspectFill;
		thumbLayer.masksToBounds = YES;
		[contentView.layer addSublayer:thumbLayer];
		[thumbLayers addObject:thumbLayer];
		UIImage *image = [thumbDataSource imageForThumbView:self forIndex:tn+curUpperLeftIndex];
		if (image != nil) {
			thumbLayer.contents = (id)image.CGImage;
		}
	}
	while ([thumbLayers count] > numThumbLayers) {
		CALayer *thumbLayer = [thumbLayers lastObject];
		[thumbLayer removeFromSuperlayer];
		[thumbLayers removeLastObject];
	}
	
	NSUInteger nr = ((np - 1) / numCols) + 1;
	contentView.frame = CGRectMake(0.0f,
								   0.0f + thumbSpacing,
								   self.bounds.size.width,
								   /*44.0f +*/ /*thumbSpacing +*/ (nr * (thumbSize + thumbSpacing)) - thumbSpacing);
	self.contentSize = contentView.bounds.size;

	NSUInteger curRow = curUpperLeftIndex / numCols;
	
	CGPoint curPos = CGPointMake(thumbSpacing + (thumbSize / 2.0f), (thumbSize/2.0f)/*44.0f*/ + (curRow * (thumbSpacing + thumbSize)));
	CGRect curBounds = CGRectMake(0.0f, 0.0f, thumbSize, thumbSize);
	NSUInteger idx = 0;
	for (CALayer *thumbLayer in thumbLayers) {
		thumbLayer.position = curPos;
		thumbLayer.bounds = curBounds;
		idx++;
		if (idx < numCols) {
			curPos.x += (thumbSize + thumbSpacing);
		} else {
			idx = 0;
			curPos.x = thumbSpacing + (thumbSize / 2.0f);
			curPos.y += (thumbSize + thumbSpacing);
		}
	}

	[CATransaction commit];
}


#pragma mark - DAThumbView

- (void) calculateLayerSpacing
{
	struct layout_s { NSUInteger cols; NSUInteger rows; CGFloat size; CGFloat spacing; };
	static struct layout_s layouts[2][2][5] = {
		{ // iPhone
			{ // portrait
				{ 2, 2, 148.0f, 8.0f },
				{ 3, 4, 96.0f, 8.0f },
				{ 4, 5, 75.0f, 4.0f },
				{ 4, 5, 75.0f, 4.0f },
				{ 4, 5, 75.0f, 4.0f }
			},
			{ // landscape
				{ 2, 1, 212.0f, 12.0f },
				{ 3, 1, 136.0f, 13.0f },
				{ 4, 2, 100.0f, 12.0f },
				{ 5, 2, 80.0f, 10.0f },
				{ 6, 3, 72.0f, 6.0f }
			}
		},
		{ // iPad
			{ // portrait
				{ 4, 7, 177.0f, 12.0f },
				{ 5, 7, 138.0f, 13.0f },
				{ 6, 7, 121.0f, 6.0f },
				{ 6, 7, 121.0f, 6.0f },
				{ 6, 7, 121.0f, 6.0f }
			},
			{ // landscape
				{ 4, 5, 241.0f, 12.0f },
				{ 5, 5, 188.0f, 14.0f },
				{ 6, 5, 159.0f, 10.0f },
				{ 7, 5, 136.0f, 9.0f },
				{ 8, 5, 119.0f, 8.0f }
			}
		}
	};
	
	NSUInteger idx1, idx2, idx3;
	
	BOOL portrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		if (portrait) {
			idx1 = 0;
			idx2 = 0;
		} else {
			idx1 = 0;
			idx2 = 1;
		}
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (portrait) {
			idx1 = 1;
			idx2 = 0;
		} else {
			idx1 = 1;
			idx2 = 1;
		}
	}
	
	NSUInteger np = [thumbDataSource numPhotosForThumbView:self];
	
	for (idx3 = 0; idx3 < 4; idx3++) {
		if ((layouts[idx1][idx2][idx3].rows * layouts[idx1][idx2][idx3].cols) >= np) {
			break;
		}
	}
	numCols = layouts[idx1][idx2][idx3].cols;
	numRows = layouts[idx1][idx2][idx3].rows + 2;
	thumbSize = layouts[idx1][idx2][idx3].size;
	thumbSpacing = layouts[idx1][idx2][idx3].spacing;
}

- (void) didAppear
{
}

- (void) reloadImages
{
}

- (void) imageLoaded:(UIImage*)image forIndex:(NSUInteger)index
{
	if (index < curUpperLeftIndex) {
		return;
	}
	index -= curUpperLeftIndex;
	if (index >= [thumbLayers count]) {
		return;
	}
	CALayer *thumbLayer = [thumbLayers objectAtIndex:index];
	thumbLayer.contents = (id)image.CGImage;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	touchMoved = YES;

	NSUInteger topRow = MAX(0.0f,self.contentOffset.y) / (thumbSize + thumbSpacing);
	NSUInteger upperLeftIndex = topRow * numCols;
	NSUInteger np = [thumbDataSource numPhotosForThumbView:self];

	if (upperLeftIndex < curUpperLeftIndex) {
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		
		NSUInteger numToMove = curUpperLeftIndex - upperLeftIndex;
		for (NSUInteger i = 0; i < numToMove; i++) {
			CALayer *thumbLayer = [thumbLayers lastObject];
			[thumbLayers insertObject:thumbLayer atIndex:0];
			[thumbLayers removeLastObject];
		}
		for (NSUInteger i = 0; i < numToMove; i++) {
			CALayer *thumbLayer = [thumbLayers objectAtIndex:i];
			UIImage *image = [thumbDataSource imageForThumbView:self forIndex:upperLeftIndex+i];
			if (image != nil) {
				thumbLayer.contents = (id)image.CGImage;
			}
		}
		curUpperLeftIndex = upperLeftIndex;
		[self setNeedsLayout];

		[CATransaction commit];

		return;
	}
	
	if (upperLeftIndex > curUpperLeftIndex) {
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		
		NSUInteger numToMove = upperLeftIndex - curUpperLeftIndex;
		for (NSUInteger i = 0; i < numToMove; i++) {
			CALayer *thumbLayer = [thumbLayers objectAtIndex:0];
			[thumbLayers addObject:thumbLayer];
			[thumbLayers removeObjectAtIndex:0];
		}
		for (NSUInteger i = 0; i < numToMove; i++) {
			NSUInteger idx = [thumbLayers count] - numToMove + i;
			CALayer *thumbLayer = [thumbLayers objectAtIndex:idx];
			if (idx < np) {
				UIImage *image = [thumbDataSource imageForThumbView:self forIndex:upperLeftIndex+idx];
				if (image != nil) {
					thumbLayer.contents = (id)image.CGImage;
				} else {
					thumbLayer.contents = nil;
				}
			} else {
				thumbLayer.contents = nil;
			}
		}
		curUpperLeftIndex = upperLeftIndex;
		[self setNeedsLayout];

		[CATransaction commit];

		return;
	}
}


#pragma mark - UIScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	touchMoved = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touchMoved) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:contentView];
//	point.y += 64.0f + thumbSpacing;
	CALayer *thumbLayer = [contentView.layer hitTest:point];
	NSUInteger index = [thumbLayers indexOfObject:thumbLayer];
	if (index == NSNotFound) {
		return;
	}
	index += curUpperLeftIndex;
	if (index >= [thumbDataSource numPhotosForThumbView:self]) {
		return;
	}
	[thumbDelegate thumbSelected:index];
}

@end
