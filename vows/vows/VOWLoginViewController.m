//
//  VOWLoginViewController.m
//  vows
//
//  Created by Zachary Weiner on 1/3/15.
//  Copyright (c) 2015 com.mostbestawesome. All rights reserved.
//

#import "VOWLoginViewController.h"
#import <PFFacebookUtils.h>
#import "VOWConstants.h"
#import <Parse.h>
@interface VOWLoginViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSMutableData *imageData;
@end

@implementation VOWLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [self updateUserInformation];
        NSLog(@"the user is already signed in ");
        [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)loginButtonPressed:(UIButton *)sender {
    
    
    NSArray *permissionsArray = @[ @"user_about_me", @"user_interests", @"user_relationships", @"user_birthday", @"user_location", @"user_relationship_details"];
    if (![PFUser currentUser]) {
        [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
            [self.activityIndicator stopAnimating]; // stop animation of activity indicator
            if (!user) {
                if (!error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"The Facebook login was cancelled." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                    [alert show];
                    
                } else {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                    [alert show];
                }
                
            } else {
                [self updateUserInformation];
                [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
            }
        }];
    }else{
        [self updateUserInformation];
        [self performSegueWithIdentifier:@"loginToTabBarSegue" sender:self];
    }
    [self.activityIndicator startAnimating]; // Show loading indicator until login is finished
}

#pragma mark Helpers 
- (void)updateUserInformation
{
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error){
            NSDictionary *userDictionary = (NSDictionary *)result;
            NSString *facebookID = userDictionary[@"id"];
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            NSMutableDictionary *userProfile = [[NSMutableDictionary alloc] initWithCapacity:8];
            if(userDictionary[@"name"]){
                userProfile[kVOWUserProfileNameKey] = userDictionary[@"name"];
            }
            if(userDictionary[@"first_name"]){
                userProfile[kVOWUserProfileFirstNameKey] = userDictionary[@"first_name"];
            }
            if(userDictionary[@"location"][@"name"]){
                userProfile[kVOWUserProfileLocationKey] = userDictionary[@"location"][@"name"];
            }
            if(userDictionary[@"gender"]){
                userProfile[kVOWUserProfileGenderKey] = userDictionary[@"gender"];
            }
            if(userDictionary[@"birthday"]){
                userProfile[kVOWUserProfileBirthdayKey] = userDictionary[@"birthday"];
            }
            if(userDictionary[@"interested_in"]){
                userProfile[kVOWUserProfileInterestedInKey] = userDictionary[@"interested_in"];
            }
            if ([pictureURL absoluteString]){
                userProfile[kVOWUserProfilePictureURL] = [pictureURL absoluteString];
            }
            
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            [[PFUser currentUser] saveInBackground];
            [self requestImage];
        }else{
            NSLog(@"Error in facebook request");
        }
    }];
}

- (void)uploadPFFileToParse:(UIImage *)image{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    if(!imageData){
        NSLog(@"error getting data from image");
        return;
    }
    PFFile *profileImage = [PFFile fileWithData:imageData];
    [profileImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            NSLog(@"error saving PFFiletoParse: %@", error);
            return;
        }
        PFObject *photo = [PFObject objectWithClassName:kVOWPhotoClassKey];
        [photo setObject:[PFUser currentUser] forKey:kVOWPhotoUserKey];
        [photo setObject:profileImage forKey:kVOWPhotoPictureKey];
        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                NSLog(@"Saved PhotoFile PFObject after saving Image data");
            }else{
                NSLog(@"Error saving PhotoFile PFObject after saving Image data");
            }
        }];
    }];
}

- (void)requestImage
{
    PFQuery *query = [PFQuery queryWithClassName:kVOWPhotoClassKey];
    [query whereKey:kVOWPhotoUserKey equalTo:[PFUser currentUser]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(number == 0){
            self.imageData = [[NSMutableData alloc] init];
            NSURL *profilePictureUrl = [NSURL URLWithString:[PFUser currentUser][kVOWUserProfileKey][kVOWUserProfilePictureURL]];
            NSURLRequest *request = [NSURLRequest requestWithURL:profilePictureUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:4.0];
            
            //We conform to the NSURLConnectionDelegate Protocol to get the NSData as its returned
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            if(!connection){
                NSLog(@"Failed to Download Image");
            }
        }else{
            NSLog(@"There were 0 photos returned");
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.imageData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UIImage *profileImage = [UIImage imageWithData:self.imageData];
    [self uploadPFFileToParse:profileImage];
    
}
@end
