//
//  DAPhoto.h
//  DAPhotoViewer
//
//  Created by David Levi on 9/8/11.
//  Copyright 2011 Double-Apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DAPhoto : NSObject

@property (nonatomic,retain) NSString *caption;
@property (nonatomic,retain) NSString *urlLarge;
@property (nonatomic,retain) NSString *urlSmall;
@property (nonatomic,retain) NSString *urlThumb;

@end
