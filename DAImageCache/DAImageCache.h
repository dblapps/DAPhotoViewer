//
//  DAImageCache.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kDAImageCache_ImageLoaded @"DAImageCacheImageLoaded"
#define kDAImageCache_ImageLoadFailed @"DAImageCacheImageLoadFailed"


@interface DAImageCache : NSObject {
	NSMutableDictionary *cache;
}

@property (assign) NSUInteger maxCacheEntries;
@property (assign) NSUInteger maxCacheMemory;
@property (readonly) NSUInteger curCacheMemory;

+ (DAImageCache*) sharedCache;

- (void) flushCache;

- (UIImage*) imageFromFile:(NSString*)file;
- (UIImage*) imageFromURL:(NSString*)url;

- (void) cancelImage:(NSString*)fileOrUrl;

@end
