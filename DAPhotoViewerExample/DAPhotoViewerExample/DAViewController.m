//
//  DAViewController.m
//  DAPhotoViewerExample
//
//  Created by David Levi on 1/25/13.
//  Copyright (c) 2013 Double Apps Inc. All rights reserved.
//

#import "DAViewController.h"
#import "DAPhotoViewController.h"
#import "DAPhoto.h"

@interface DAViewController ()

@end

@implementation DAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)viewPhotos:(id)sender
{
	DAPhoto *photo[8];
	
	photo[0] = [[DAPhoto alloc] init];
	photo[0].caption = @"photo1 this is a long caption because we like to test things to make sure they work and are not broken so don't argue and just do the testing before I open a can of whack-a-mole on your lazy trout but you pig head";
	photo[0].urlLarge = @"IMG_0534.jpg";
	photo[0].urlSmall = @"IMG_0534s.png";
	photo[0].urlThumb = @"IMG_0534s.png";
	
	photo[1] = [[DAPhoto alloc] init];
	photo[1].caption = @"photo2";
	photo[1].urlLarge = @"IMG_0540.jpg";
	photo[1].urlSmall = @"IMG_0540s.png";
	photo[1].urlThumb = @"IMG_0540s.png";
	
	photo[2] = [[DAPhoto alloc] init];
	photo[2].caption = @"photo3";
	photo[2].urlLarge = @"IMG_0541.jpg";
	photo[2].urlSmall = @"IMG_0541s.png";
	photo[2].urlThumb = @"IMG_0541s.png";
	
	photo[3] = [[DAPhoto alloc] init];
	photo[3].caption = @"photo4";
	photo[3].urlLarge = @"IMG_0542.jpg";
	photo[3].urlSmall = @"IMG_0542s.png";
	photo[3].urlThumb = @"IMG_0542s.png";
	
	photo[4] = [[DAPhoto alloc] init];
	photo[4].caption = @"photo5";
	photo[4].urlLarge = @"IMG_0543.jpg";
	photo[4].urlSmall = @"IMG_0543s.png";
	photo[4].urlThumb = @"IMG_0543s.png";
	
	photo[5] = [[DAPhoto alloc] init];
	photo[5].caption = @"photo6";
	photo[5].urlLarge = @"IMG_0544.jpg";
	photo[5].urlSmall = @"IMG_0544s.png";
	photo[5].urlThumb = @"IMG_0544s.png";
	
	photo[6] = [[DAPhoto alloc] init];
	photo[6].caption = @"photo6";
	photo[6].urlLarge = @"IMG_0879.jpg";
	photo[6].urlSmall = @"IMG_0879s.png";
	photo[6].urlThumb = @"IMG_0879s.png";
	
	photo[7] = [[DAPhoto alloc] init];
	photo[7].caption = @"photo6";
	photo[7].urlLarge = @"IMG_0880.jpg";
	photo[7].urlSmall = @"IMG_0880s.png";
	photo[7].urlThumb = @"IMG_0880s.png";
	
	DAPhotoSet *photoSet = [[DAPhotoSet alloc] init];
	photoSet.title = @"Photo Set";
	photoSet.photos = @[ photo[0], photo[1], photo[2], photo[3], photo[4], photo[5], photo[6], photo[7] ];
	
	DAPhotoViewController *photoViewController = [[DAPhotoViewController alloc] init];
	photoViewController.photoSet = photoSet;
	[self.navigationController pushViewController:photoViewController animated:YES];
}

@end
