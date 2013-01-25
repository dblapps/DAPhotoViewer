//
//  DAImage.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DAImage;

@protocol DAImageDelegate
- (void) finishedLoading:(DAImage*)daImage;
- (void) failedLoading:(DAImage*)daImage;
@end

@interface DAImage : NSObject {
	NSURL *url;
	NSURLConnection *urlConnection;
	NSMutableData *imageData;
}

@property (assign) id<DAImageDelegate> delegate;
@property (readonly) NSString *name;
@property (readonly) UIImage *image;
@property (readonly) BOOL loading;
@property (assign) NSUInteger loadingCount;
@property (assign) NSTimeInterval lastAccess;
@property (readonly) NSUInteger memoryUsage;

- (id) initWithUrl:(NSString*)_url;

- (void) startLoad;
- (void) cancelLoad;

@end
