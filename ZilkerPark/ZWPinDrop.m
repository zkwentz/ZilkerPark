//
//  ZWPinDrop.m
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/18/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import "ZWPinDrop.h"
#import <FacebookSDK/FacebookSDK.h>
#import <NSDate+TimeAgo/NSDate+TimeAgo.h>

@implementation ZWPinDrop

@synthesize profilePicture;
@synthesize nameLabel;
@synthesize contentView;
@synthesize timeAgoLabel;
@synthesize pinTip;

- (id)initWithFacebookID:(NSString*)facebookID andTimestamp:(NSDate*)timestamp
{
    if (self = [super init])
    {
        [self awakeFromNib];
        // Send request to Facebook
        [FBRequestConnection startWithGraphPath:facebookID completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            nameLabel.text = userData[@"name"];
            timeAgoLabel.text = [timestamp timeAgo];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            //[droppedPin setImageWithURL:pictureURL];
            [profilePicture setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:pictureURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                
                profilePicture.image = image;
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                //do nothing
            }];
        }];
    }
    return self;
}

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

- (IBAction)imageTapped:(UITapGestureRecognizer *)sender {
    nameLabel.alpha = 1;
    timeAgoLabel.alpha = 1;
}

- (void)counterZoom:(CGFloat)scale atPoint:(CGPoint)point
{
    nameLabel.font = [UIFont systemFontOfSize:(17/scale)];
    timeAgoLabel.font = [UIFont systemFontOfSize:(10/scale)];
    CGFloat pinWidth = 275 / scale;
    CGFloat pinHeight = 122 / scale;
    pinTip.frame = CGRectMake(pinTip.frame.origin.x, pinTip.frame.origin.y, 2 / scale, pinTip.frame.size.height);
    contentView.frame = CGRectMake(point.x - pinTip.frame.origin.x, point.y - pinHeight, pinWidth, pinHeight);
}

@end
