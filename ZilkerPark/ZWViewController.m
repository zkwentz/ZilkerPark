//
//  ZWViewController.m
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/11/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import "ZWViewController.h"
#import <NSDate+TimeAgo/NSDate+TimeAgo.h>

@interface ZWViewController ()
{
    NSMutableDictionary *pins;
    bool checkingIn;
    NSUserDefaults *defaults;
    NSArray *friends;
}
@end

@implementation ZWViewController

@synthesize scroller;
@synthesize map;
@synthesize mapWrapper;

@synthesize checkIn;
@synthesize singleTapRecognizer;
@synthesize doubleTapRecognizer;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    scroller.contentSize = self.mapWrapper.frame.size;
    CGRect zoomRect = [self zoomRectForScale:scroller.minimumZoomScale
                                  withCenter:self.view.center];
    [self.scroller zoomToRect:zoomRect animated:YES];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    pins = [[NSMutableDictionary alloc] init];
    checkingIn = false;
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    
    //Hide status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

#pragma mark Status bar methods
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark View Controller Methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![PFUser currentUser]) { // No user logged in
        // Create the log in view controller
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        [logInViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        [logInViewController setFields:PFLogInFieldsFacebook];
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    } else {
        [self update];
    }
}

- (void)update {
    
    // Issue a Facebook Graph API request to get your user's friend list
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result will contain an array with your user's friends in the "data" key
            NSArray *friendObjects = [result objectForKey:@"data"];
            NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
            // Create a list of friends' Facebook IDs
            for (NSDictionary *friendObject in friendObjects) {
                [friendIds addObject:[friendObject objectForKey:@"id"]];
            }
            
            // Construct a PFUser query that will find friends whose facebook ids
            // are contained in the current user's friend list.
            PFQuery *friendQuery = [PFUser query];
            [friendQuery whereKey:@"fbId" containedIn:friendIds];
            
            // findObjects will return a list of PFUsers that are friends
            // with the current user
            friends = [friendQuery findObjects];
            
            for (PFUser *friend in friends)
            {
                PFQuery *query = [PFQuery queryWithClassName:@"UserLocation"];
                [query whereKey:@"user" equalTo:friend];
                NSDate *cutoffDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-18000]; //time before 45min
                [query whereKey:@"updatedAt" greaterThan:cutoffDate];
                
                [query findObjectsInBackgroundWithBlock:^(NSArray *locations, NSError *error) {
                    PFObject* lastLocation = [locations lastObject];
                    if (lastLocation)
                    {
                        CGPoint point = CGPointMake([[lastLocation objectForKey:@"x"] intValue], [[lastLocation objectForKey:@"y"] intValue]);
                        [self dropPinAtPoint:point withID:[friend objectForKey:@"fbId"]];
                    }
                }];
            }
        }
    }];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserLocation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    NSDate *cutoffDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-18000]; //time before 45min
    [query whereKey:@"updatedAt" greaterThan:cutoffDate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *locations, NSError *error) {
        PFObject* lastLocation = [locations lastObject];
        if (lastLocation)
        {
            CGPoint point = CGPointMake([[lastLocation objectForKey:@"x"] intValue], [[lastLocation objectForKey:@"y"] intValue]);
            [self dropPinAtPoint:point withID:[[PFUser currentUser] objectForKey:@"fbId"]];
        }
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [mapWrapper frame].size.height / scale;
    zoomRect.size.width  = [mapWrapper frame].size.width  / scale;
    
    center = [mapWrapper convertPoint:center fromView:scroller];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

#pragma mark UIScrollViewDelegate

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return mapWrapper;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    for(id key in pins)
    {
        NSDictionary* pinDesc = [pins objectForKey:key];
        ZWPinDrop* pinDrop = (ZWPinDrop*)[pinDesc objectForKey:@"view"];
        UIView* pin = pinDrop.contentView;
        CGPoint point = [[pinDesc objectForKey:@"point"] CGPointValue];
        pinDrop.nameLabel.font = [UIFont systemFontOfSize:(17 / scroller.zoomScale)];
        pin.frame = [self pinFrame:point];
    }
}

- (IBAction)doubleTap:(UITapGestureRecognizer *)recognizer {
    
    if(scroller.zoomScale > scroller.minimumZoomScale)
    {
        [scroller setZoomScale:scroller.minimumZoomScale animated:YES];
        [self hideCheckIn:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:scroller.maximumZoomScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [scroller zoomToRect:zoomRect animated:YES];
        [self hideCheckIn:NO];
    }
}

- (void)hideCheckIn:(BOOL)shouldHide
{
    //checkIn.hidden = shouldHide;
}

- (IBAction)checkInPress:(UIButton *)sender {
    if (checkingIn)
    {
        //CGRect zoomRect = [self zoomRectForScale:scroller.minimumZoomScale
        //                              withCenter:self.view.center];
        //[self.scroller zoomToRect:zoomRect animated:YES];
        [checkIn setTitle:@"Check In" forState:UIControlStateNormal];
    }
    else
    {
        //CGRect zoomRect = [self zoomRectForScale:scroller.maximumZoomScale
        //                              withCenter:CGPointMake(0, 320)];
        //[scroller zoomToRect:zoomRect animated:YES];
        [checkIn setTitle:@"Done" forState:UIControlStateNormal];
    }
    checkingIn = !checkingIn;
}

- (IBAction)pinDropped:(UITapGestureRecognizer *)recognizer {
    if (scroller.zoomScale > scroller.minimumZoomScale && checkingIn)
    {
        CGPoint center = [mapWrapper convertPoint:[recognizer locationInView:recognizer.view] fromView:scroller];
        [self dropPinAtPoint:center withID:[[PFUser currentUser] objectForKey:@"fbId"]];
        PFObject *currentLocation = [PFObject objectWithClassName:@"UserLocation"];
        currentLocation[@"x"] = [NSNumber numberWithInt:center.x];
        currentLocation[@"y"] = [NSNumber numberWithInt:center.y];
        currentLocation[@"user"] = [PFUser currentUser];
        [currentLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            PFUser *user = [PFUser currentUser];
            PFRelation *relation = [user relationforKey:@"location"];
            [relation addObject:currentLocation];
            [user saveInBackground];
        }];
        //TODO: store friends and send the push notifications//
        /*if ([defaults boolForKey:@"NotifyFriends"])
        {
            NSString* alertMessage = [NSString stringWithFormat:@"%@ just checked in to Zilker Park!",[defaults stringForKey:@"name"]];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            [push setMessage:alertMessage];
            [push sendPushInBackground];
        }*/
    }
}

- (void)dropPinAtPoint:(CGPoint)point withID:(NSString*)facebookID
{
    //[pin setObject:urlConnection forKey:@"connection"];
    if ([pins objectForKey:facebookID])
    {
        [(ZWPinDrop*)[(NSDictionary*)[pins objectForKey:facebookID] objectForKey:@"view"]  removeFromSuperview];
        [pins removeObjectForKey:facebookID];
    }
    
    NSMutableDictionary *pin = [[NSMutableDictionary alloc] initWithCapacity:2];
    //ZWPinDrop * droppedPin = [[[NSBundle mainBundle] loadNibNamed:@"ZWPinDrop" owner:self options:nil] firstObject];
    ZWPinDrop *droppedPin = [[ZWPinDrop alloc] init];
    [droppedPin awakeFromNib];
    droppedPin.contentView.frame = [self pinFrame:point];
    droppedPin.contentView.alpha = 1;
    droppedPin.contentView.backgroundColor = [UIColor clearColor];
    droppedPin.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    droppedPin.contentView.layer.shadowOpacity = 0.5;
    droppedPin.contentView.layer.shadowOffset = CGSizeMake(5.0, 5.0);
    [mapWrapper addSubview:droppedPin];
    [mapWrapper bringSubviewToFront:droppedPin];
    [pin setValue:[NSValue valueWithCGPoint:point] forKey:@"point"];
    [pin setValue:droppedPin forKey:@"view"];
    [pins setObject:pin forKey:facebookID];
    
    UIView* pointDrop = [[UIView alloc] initWithFrame:CGRectMake(point.x-10, point.y-10, 20, 20)];
    pointDrop.backgroundColor = [UIColor redColor];
    [mapWrapper addSubview:pointDrop];
    [mapWrapper bringSubviewToFront:pointDrop];
    
    // Send request to Facebook
    [FBRequestConnection startWithGraphPath:facebookID completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        // result is a dictionary with the user's Facebook data
        NSDictionary *userData = (NSDictionary *)result;
        
        [defaults setObject:userData[@"id"] forKey:@"facebookID"];
        [defaults setObject:userData[@"name"] forKey:@"name"];
        
        NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
        
        __weak UIImageView* _picture = droppedPin.profilePicture;
        
        //[droppedPin setImageWithURL:pictureURL];
        [droppedPin.profilePicture setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:pictureURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            _picture.image = [image imageWithRoundedBounds];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            //do nothing
        }];
        //droppedPin.image = [droppedPin.image imageWithCornerRadius:25.0f];
            

    }];
    
}

- (CGRect)pinFrame:(CGPoint)point
{
    CGFloat scale = scroller.zoomScale;
    CGFloat pinWidth = 275 / scale;
    CGFloat pinHeight = 122 / scale;
    
    return CGRectMake(point.x - (36 / scale), point.y-pinHeight,pinWidth,pinHeight);
}

#pragma mark PFLogInViewControllerDelegate

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

- (IBAction)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    if (user) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // Store the current user's Facebook ID on the user
                [[PFUser currentUser] setObject:[result objectForKey:@"id"]
                                         forKey:@"fbId"];
                [[PFUser currentUser] saveInBackground];
                [self dismissViewControllerAnimated:YES completion:NULL];
            }
        }];
    }
}


// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
