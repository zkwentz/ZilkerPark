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
@synthesize pinTip;

-(void)awakeFromNib {
    //Note that you must change @”BNYSharedView’ with whatever your nib is named
    [[NSBundle mainBundle] loadNibNamed:@"ZWPinDrop" owner:self options:nil];
    [self addSubview: self.contentView];
    contentView.alpha = 1;
    contentView.backgroundColor = [UIColor clearColor];
    contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    contentView.layer.shadowOpacity = 0.5;
    contentView.layer.shadowOffset = CGSizeMake(5.0, 5.0);
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

- (void)counterZoom:(CGFloat)scale atPoint:(CGPoint)point
{
    nameLabel.font = [UIFont systemFontOfSize:(17/scale)];
    CGFloat pinWidth = 275 / scale;
    CGFloat pinHeight = 122 / scale;
    pinTip.frame = CGRectMake(pinTip.frame.origin.x, pinTip.frame.origin.y, 2 / scale, pinTip.frame.size.height);
    contentView.frame = CGRectMake(point.x - pinTip.frame.origin.x, point.y - pinHeight, pinWidth, pinHeight);
}

@end
