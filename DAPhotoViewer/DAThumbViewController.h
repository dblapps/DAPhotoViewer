//
//  DAThumbViewController.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/15/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAPhotoSet.h"
#import "DAThumbView.h"


@protocol DAThumbViewControllerDelegate
- (void) thumbSelected:(NSUInteger)thumb;
@end

@interface DAThumbViewController : UIViewController <DAThumbViewDelegate, DAThumbViewDataSource> {
	NSMutableDictionary *images;
	DAThumbView *thumbView;
}

@property(nonatomic, assign) id<DAThumbViewControllerDelegate> delegate;

@property(nonatomic, assign) UIBarStyle barStyle;
@property(nonatomic, retain) UIColor *tintColor;
@property(nonatomic,assign,getter=isTranslucent) BOOL translucent;

@property(nonatomic,retain) DAPhotoSet *photoSet;

- (void) flushImages;

@end
