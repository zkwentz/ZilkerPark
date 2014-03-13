//
//  ZWViewController.h
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/11/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ZWViewController : UIViewController <UIScrollViewDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

- (IBAction)doubleTap:(UITapGestureRecognizer *)recognizer;
- (IBAction)checkInPress:(UIButton *)sender;
- (IBAction)pinDropped:(UITapGestureRecognizer *)recognizer;
@property (weak, nonatomic) IBOutlet UIScrollView *scroller;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *singleTapRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapRecognizer;
@property (weak, nonatomic) IBOutlet UIButton *checkIn;
@property (weak, nonatomic) IBOutlet UIView *mapWrapper;
@property (weak, nonatomic) IBOutlet UIImageView *map;
@end
