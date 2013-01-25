//
//  DAPhotoSet.m
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import "DAPhotoSet.h"


@implementation DAPhotoSet

@synthesize title;
@synthesize photos;

- (NSUInteger) count;
{
	if (photos == nil) {
		return 0;
	}
	return [photos count];
}

- (id) photoAtIndex:(NSUInteger)index
{
	if (photos == nil) {
		return nil;
	}
	if (index >= [photos count]) {
		return nil;
	}
	return [photos objectAtIndex:index];
}

@end
