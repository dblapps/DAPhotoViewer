//
//  DAThumbView.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DAThumbView;


@protocol DAThumbViewDelegate <UIScrollViewDelegate>
- (void) thumbSelected:(NSUInteger)thumb;
@end


@protocol DAThumbViewDataSource
- (NSUInteger) numPhotosForThumbView:(DAThumbView*)tv;
- (UIImage*) imageForThumbView:(DAThumbView*)tv forIndex:(NSUInteger)index;
@end


@interface DAThumbView : UIScrollView <UIScrollViewDelegate> {
	NSMutableArray *thumbLayers;
	
	NSUInteger numCols;
	NSUInteger numRows;
	CGFloat thumbSize;
	CGFloat thumbSpacing;
	
	NSUInteger curUpperLeftIndex; // index of the thumb currently in the upper left of the contentView
	
	UIView *contentView;
	
	BOOL touchMoved;
}

@property (nonatomic, assign) id<DAThumbViewDelegate> thumbDelegate;
@property (nonatomic, assign) id<DAThumbViewDataSource> thumbDataSource;

- (void) didAppear;
- (void) reloadImages;

- (void) imageLoaded:(UIImage*)image forIndex:(NSUInteger)index;

@end
