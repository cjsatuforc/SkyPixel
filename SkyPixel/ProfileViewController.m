//
//  ProfileViewController.m
//  SkyPixel
//
//  Created by Xie kesong on 12/25/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "ProfileViewController.h"
#import "UIImageView+ProfileAvator.h"
#import "HorizontalSlideInAnimator.h"
#import "ProfileTableViewController.h"

@interface ProfileViewController()

@property (weak, nonatomic) IBOutlet UIImageView *avatorImageView;
@property (weak, nonatomic) IBOutlet UILabel *fullnameLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverHeightConstriant;
@property (weak, nonatomic) IBOutlet UILabel *bioLabel;
@property (weak, nonatomic) IBOutlet UIButton *followBtn;
@property (nonatomic) CGFloat orginCoverHeight;

@end

@implementation ProfileViewController

-(void)viewDidLoad{
    [super viewDidLoad];
//    self.navigationController.navigationBarHidden = YES;
//    self.scrollView.delegate = self;
//    self.scrollView.alwaysBounceVertical = YES;
//    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
//    User* loggedInUser = [[User alloc]initWithRecord:delegate.loggedInRecord];
//    [self.avatorImageView becomeAvatorProifle:loggedInUser.thumbImage];
//    self.avatorImageView.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.avatorImageView.layer.borderWidth = 3.0;
//    self.fullnameLabel.text = loggedInUser.fullname;
//    self.coverImageView.image = loggedInUser.coverThumbImage;
//    self.bioLabel.text = loggedInUser.bio;
//    self.followBtn.layer.cornerRadius = 3.0;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(avatorTapped:)];
    self.avatorImageView.userInteractionEnabled = YES;
    [self.avatorImageView addGestureRecognizer:tap];
    
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //[self adjustCoverView];
}

-(void)adjustCoverView{
    CGSize coverImageSize = self.coverImageView.image.size;
    self.coverHeightConstriant.constant = self.view.frame.size.width * coverImageSize.height /  coverImageSize.width;
    self.orginCoverHeight = self.coverHeightConstriant.constant;
}

-(void)avatorTapped:(UITapGestureRecognizer*)gesture{
    NSLog(@"tapped");
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ProfileTableViewController* profileTVC =  (ProfileTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ProfileTableViewController"];
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    User* loggedInUser = [[User alloc]initWithRecord:delegate.loggedInRecord];

    profileTVC.transitioningDelegate = self;
    profileTVC.user = loggedInUser;
    [self presentViewController:profileTVC animated:YES completion:nil];
    
}





//MARK: UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if(scrollView.contentOffset.y < 0){
        CGRect coverRect = CGRectMake(0, scrollView.contentOffset.y,self.coverImageView.frame.size.width, self.orginCoverHeight + (-scrollView.contentOffset.y));
        self.coverImageView.frame = coverRect;
    }
}



-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    HorizontalSlideInAnimator* animator = [[HorizontalSlideInAnimator alloc] init];
    return animator;
}






@end
