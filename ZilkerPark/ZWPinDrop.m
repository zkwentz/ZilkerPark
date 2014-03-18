//
//  ZWPinDrop.m
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/18/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import "ZWPinDrop.h"

@implementation ZWPinDrop

@synthesize profilePicture;
@synthesize nameLabel;
@synthesize timeAgoLabel;

- (void)awakeFromNib
{
    nameLabel.alpha = 0;
    timeAgoLabel.alpha = 0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)imageTapped:(UITapGestureRecognizer *)sender {
    nameLabel.alpha = 1;
    timeAgoLabel.alpha = 1;
}
@end
