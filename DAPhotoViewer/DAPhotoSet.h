//
//  DAPhotoSet.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DAPhotoSet : NSObject

@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSArray *photos;

- (NSUInteger) count;
- (id) photoAtIndex:(NSUInteger)index;

@end
