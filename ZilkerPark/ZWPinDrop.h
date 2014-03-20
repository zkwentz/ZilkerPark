//
//  ZWPinDrop.h
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/18/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZWPinDrop : UIView


@property (nonatomic, weak) IBOutlet UIImageView* profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
