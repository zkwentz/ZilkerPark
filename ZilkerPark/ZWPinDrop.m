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
@synthesize contentView;
@synthesize timeAgoLabel;

-(void)awakeFromNib {
    //Note that you must change @”BNYSharedView’ with whatever your nib is named
    [[NSBundle mainBundle] loadNibNamed:@"ZWPinDrop" owner:self options:nil];
    [self addSubview: self.contentView];
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
