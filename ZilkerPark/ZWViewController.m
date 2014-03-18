//
//  ZWViewController.m
//  ZilkerPark
//
//  Created by Zachary Wentz on 3/11/14.
//  Copyright (c) 2014 Zach Wentz. All rights reserved.
//

#import "ZWViewController.h"

@interface ZWViewController ()
{
    UIImageView *droppedPin;
    NSMutableData* imageData;
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
    //[scroller scrollRectToVisible:CGRectMake(-852, -460, 568, 320) animated:NO];
    //[scroller setZoomScale:scroller.minimumZoomScale animated:NO];
    CGRect zoomRect = [self zoomRectForScale:scroller.minimumZoomScale
                                  withCenter:self.view.center];
    [self.scroller zoomToRect:zoomRect animated:YES];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
}

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
            NSArray *friendUsers = [friendQuery findObjects];
        }
    }];
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserLocation"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *locations, NSError *error) {
        PFObject* lastLocation = [locations lastObject];
        CGPoint point = CGPointMake([[lastLocation objectForKey:@"x"] intValue], [[lastLocation objectForKey:@"y"] intValue]);
        [self dropPinAtPoint:point];
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
    CGRect zoomRect = [self zoomRectForScale:scroller.maximumZoomScale
                                  withCenter:CGPointMake(0, 320)];
    [scroller zoomToRect:zoomRect animated:YES];
}

- (IBAction)pinDropped:(UITapGestureRecognizer *)recognizer {
    if (scroller.zoomScale > scroller.minimumZoomScale)
    {
        CGPoint center = [mapWrapper convertPoint:[recognizer locationInView:recognizer.view] fromView:scroller];
        [self dropPinAtPoint:center];
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
    }
}

- (void)dropPinAtPoint:(CGPoint)point
{
    FBRequest *request = [FBRequest requestForMe];
    
    // Send request to Facebook
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            NSString *name = userData[@"name"];
            NSString *location = userData[@"location"][@"name"];
            NSString *gender = userData[@"gender"];
            NSString *birthday = userData[@"birthday"];
            NSString *relationship = userData[@"relationship_status"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            // Now add the data to the UI elements
            // ...
            
            // Download the user's facebook profile picture
            imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
            
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                  timeoutInterval:2.0f];
            // Run network request asynchronously
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
            
            
            [droppedPin removeFromSuperview];
            droppedPin = [[UIImageView alloc] initWithFrame:CGRectMake(point.x - 50, point.y - 50,100,100)];
            droppedPin.alpha = 1;
            droppedPin.backgroundColor = [UIColor blueColor];
            droppedPin.layer.shadowColor = [UIColor blackColor].CGColor;
            droppedPin.layer.shadowOpacity = 0.5;
            droppedPin.layer.shadowOffset = CGSizeMake(5.0, 5.0);
            [mapWrapper addSubview:droppedPin];
            [mapWrapper bringSubviewToFront:droppedPin];
        }
    }];
    
}

#pragma mark NSURLConnectionDelegate

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image in the header imageView
    droppedPin.image = [UIImage imageWithData:imageData];
    droppedPin.layer.cornerRadius = 50;
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
