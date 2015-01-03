//
//  VOWProfileViewController.m
//  vows
//
//  Created by Zachary Weiner on 1/3/15.
//  Copyright (c) 2015 com.mostbestawesome. All rights reserved.
//

#import "VOWProfileViewController.h"
#import <Parse/Parse.h>
#import "VOWConstants.h"
@interface VOWProfileViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation VOWProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    PFQuery *query = [PFQuery queryWithClassName:kVOWPhotoClassKey];
    [query whereKey:kVOWPhotoUserKey equalTo:[PFUser currentUser]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"error getinng objects in background");
            return;
        }
        if([objects count]> 0){
            PFFile *profileImage = ((PFFile *)objects[0][kVOWPhotoPictureKey]);
            [profileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                self.imageView.image = [UIImage imageWithData:data];
            }];
        }else{
            NSLog(@"There were 0 items returned for user Photos");
        }
    }];
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

@end
