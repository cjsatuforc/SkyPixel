//
//  CastingViewController.m
//  SkyPixel
//
//  Created by Xie kesong on 12/12/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//

#import  <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import "CastingViewController.h"
#import "PlayView.h"
#import "FavorUserListViewController.h"
#import "CommentListViewController.h"
#import "ProfileTableViewController.h"

static NSString* const FavorIconWhite = @"favor-icon";
static NSString* const FavorIconRed = @"favor-icon-red";

@interface CastingViewController()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *avatorImageView;
@property (weak, nonatomic) IBOutlet UIImageView *liveIcon;
@property (weak, nonatomic) IBOutlet UILabel *fullnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewCountsLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *locationBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoHeightConstraint;


//pinFooterView properties
@property (weak, nonatomic) IBOutlet UIView *pinFooterView;
@property (weak, nonatomic) IBOutlet UIStackView *favorWrapperView;
@property (weak, nonatomic) IBOutlet UIImageView *favorIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *favorCountLabel;
@property (weak, nonatomic) IBOutlet UIStackView *commentWrapperView;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIStackView *optionWrapperView;

//video player properties
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) NSString* payerItemContext;
@property (strong, nonatomic) CKAsset* videoAsset;
@property (nonatomic) BOOL resetting;
@property (nonatomic) BOOL needsResumeSettingVideo;
@property (nonatomic) BOOL isViewVisible;




//update the user information, such as fullname, avator
-(void)updateUI;

-(void)didPlayToEnd:(NSNotification*)notification;

//this is function is responsible for updating the favor and comment count
-(void)updatePinBottomViewUI;

-(void)addTapGesture;


-(void)favorTapped: (UITapGestureRecognizer*)gesture;


//remove the given user reference form the userFavorList of referenList in video stream
-(void)addFavorForUserReferenceInVideoStream: (CKReference*) userReference videoStream: (VideoStream*) videoStream completionHandler: (void (^)(void)) callBack;

//add the given user reference to the userFavorList of referenList in video stream
-(void)deleteFavorForUserReferenceInVideoStream: (CKReference*) userReference videoStream: (VideoStream*) videoStream completionHandler: (void (^)(void)) callBack;
@end

@implementation CastingViewController

- (IBAction)backBtnTapped:(UIBarButtonItem *)sender {
    self.resetting = YES;
    [self resetPlayer];
    [self performSegueWithIdentifier:@"backFromCastingViewController" sender:self];
}


- (IBAction)backFromProfileTableViewController:(UIStoryboardSegue *)segue {
    self.resetting = NO;
    if(self.needsResumeSettingVideo && self.videoAsset != nil){
        [self readyLoadingVideo:self.videoAsset];
    }else{
        [self.player play];
    }
}

-(void) viewDidLoad{
    [super viewDidLoad];
    if(self.videoStream != nil){
        [self updateUI];
        //convert latitude and longitude to human-readable string
        CLGeocoder* geoCoder = [[CLGeocoder alloc]init];
        [geoCoder reverseGeocodeLocation:self.videoStream.location completionHandler:^(NSArray* placemarks, NSError* error){
            if(error == nil){
                CLPlacemark* placeMark = placemarks.lastObject;
                [self.locationBtn setTitle: placeMark.name forState:UIControlStateNormal];
            }
        }];
    }
    //load asset
    [self.activityIndicator startAnimating];
    [self.videoStream loadVideoAsset:^(CKAsset *videoAsset, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!self.resetting){
                [self readyLoadingVideo: videoAsset];
            }else{
                //need to resume setting video
                self.needsResumeSettingVideo = YES;
                self.videoAsset = videoAsset;
            }
        });
    }];
    [self addTapGesture];
}

-(void)addTapGesture{
    //add tap gesture for the icon
    UITapGestureRecognizer* favorTapped = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(favorTapped:)];
    [self.favorIconImageView addGestureRecognizer:favorTapped];
    
    //add tap gesture for the comment wrapper view
    UITapGestureRecognizer* commentWrapperTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(commentWrapperViewTapped:)];
    [self.commentWrapperView addGestureRecognizer:commentWrapperTapGesture];
    
    //add tap gesture for favorWrapperView
    UITapGestureRecognizer* favorWrapperTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(favorWrapperViewTapped:)];
    [self.favorWrapperView addGestureRecognizer:favorWrapperTapGesture];
    
    //add tap gesture for avator image view
    UITapGestureRecognizer* avatorTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(avatorImageViewTapped:)];
    [self.avatorImageView addGestureRecognizer:avatorTapGesture];
}

-(void) viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self adjustVideoFrame];
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.pinFooterView.frame.size.height, 0);
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSString* count = self.viewCountsLabel.text;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [formatter numberFromString:count];
    NSInteger newCount = myNumber.intValue + 1;
    self.viewCountsLabel.text = [NSString stringWithFormat: @"%ld", (long)newCount];
    [self updatePinBottomViewUI];
    self.isViewVisible = YES;

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.isViewVisible = NO;
}

-(void) updateUI{
    if([self.videoStream isLive]){
        self.title = @"LIVE NOW";
        [self.liveIcon setHidden:NO];
        self.viewStatusLabel.text = @"PEOPLE VIEWING";
    }
    self.fullnameLabel.text = self.videoStream.user.fullname;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData* imageData = [[NSData alloc]initWithContentsOfURL:self.videoStream.user.avatorUrl];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage* avator = [[UIImage alloc]initWithData:imageData];
            self.avatorImageView.image = avator;
        });
    });
    self.avatorImageView.layer.cornerRadius = self.avatorImageView.frame.size.height / 2;
    self.avatorImageView.clipsToBounds = YES;
    self.videoTitleLabel.text = self.videoStream.title;
    self.descriptionLabel.text = self.videoStream.description;
    if(self.descriptionLabel.text.length == 0){
        self.descriptionLabel.text = @"No description available";
        self.descriptionLabel.textColor = [UIColor colorWithRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1]; //lighter gray
    }
    [self updatePinBottomViewUI];
}

-(void)updatePinBottomViewUI{
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    CKRecordID* loggedInReferenceId = [delegate.loggedInRecord recordID];
    CKReference* loggedInReference = [[CKReference alloc]initWithRecordID:loggedInReferenceId action:CKReferenceActionNone];
    //update the favor icon wrapper view
    UIImage* heartIconImage;
    if([self.videoStream.favorUserList containsObject:loggedInReference]){
        heartIconImage = [UIImage imageNamed: FavorIconRed];
    }else{
        heartIconImage =  [UIImage imageNamed: FavorIconWhite];
    }
    self.favorIconImageView.image = heartIconImage;
    NSNumber* favorCount = [NSNumber numberWithInteger:self.videoStream.favorUserList.count];
    self.favorCountLabel.text = [[NSNumberFormatter alloc]stringFromNumber:favorCount];
    
    //update the commnet wrapper view
    NSNumber* commentCount = [NSNumber numberWithInteger:self.videoStream.commentReferenceList.count];
    self.commentCountLabel.text = [[NSNumberFormatter alloc]stringFromNumber:commentCount];
}

-(void)favorTapped: (UITapGestureRecognizer*)gesture{
    AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    CKRecordID* loggedInReferenceId = [delegate.loggedInRecord recordID];
    CKReference* loggedInReference = [[CKReference alloc]initWithRecordID:loggedInReferenceId action:CKReferenceActionDeleteSelf];
    __block UIImage* heartIconImage;
    __block NSNumber* count = [[NSNumberFormatter alloc]numberFromString:self.favorCountLabel.text];
    if([self.videoStream.favorUserList containsObject:loggedInReference]){
       //delete favor
        [self deleteFavorForUserReferenceInVideoStream:loggedInReference videoStream:self.videoStream completionHandler:^{
            heartIconImage = [UIImage imageNamed: FavorIconWhite];
            count = [NSNumber numberWithInteger:[count integerValue] - 1];
            self.favorIconImageView.image = heartIconImage;
            self.favorCountLabel.text = [[NSNumberFormatter alloc] stringFromNumber:count];
        }];
    }else{
        //add favor
        [self addFavorForUserReferenceInVideoStream:loggedInReference videoStream:self.videoStream completionHandler:^{
            heartIconImage = [UIImage imageNamed: FavorIconRed];
            count = [NSNumber numberWithInteger:[count integerValue] + 1];
            self.favorIconImageView.image = heartIconImage;
            self.favorCountLabel.text = [[NSNumberFormatter alloc] stringFromNumber:count];
        }];

    }
}





-(void)deleteFavorForUserReferenceInVideoStream: (CKReference*) userReference videoStream: (VideoStream*) videoStream completionHandler: (void (^)(void)) callBack{
    [videoStream deleteFavorUser:userReference completionHandler:^(CKRecord *videoRecord, NSError *error) {
        //update UI
        dispatch_async(dispatch_get_main_queue(), ^{
            callBack();
        });
    }];
}



-(void)addFavorForUserReferenceInVideoStream: (CKReference*) userReference videoStream: (VideoStream*) videoStream completionHandler: (void (^)(void)) callBack{
    [videoStream addFavorUser:userReference completionHandler:^(CKRecord *videoRecord, NSError *error) {
        //update UI
        dispatch_async(dispatch_get_main_queue(), ^{
            callBack();
        });
    }];
}

-(void)favorWrapperViewTapped: (UITapGestureRecognizer*)gesture{
    //segue to the favor list view controller
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FavorUserListViewController* favorUserListVC= (FavorUserListViewController*)[storyboard instantiateViewControllerWithIdentifier:@"FavorUserListViewController"];
    if(favorUserListVC){
        favorUserListVC.favorUserList = self.videoStream.favorUserList;
        [self.navigationController pushViewController:favorUserListVC animated:YES];
    }
}


-(void)commentWrapperViewTapped: (UITapGestureRecognizer*)gesture{
    //show a new segue
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CommentListViewController* commentListVC = (CommentListViewController*)[storyboard instantiateViewControllerWithIdentifier:@"CommentListViewController"];
    if(commentListVC){
        commentListVC.videoStream = self.videoStream;
        [self.navigationController pushViewController:commentListVC animated:YES];
    }
}



-(void)avatorImageViewTapped: (UITapGestureRecognizer*)gesture{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ProfileTableViewController* profileTVC = (ProfileTableViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ProfileTableViewController"];
    if(profileTVC){
        self.resetting = YES;
        [self.player pause];
        profileTVC.user = self.videoStream.user;
        [self.navigationController pushViewController:profileTVC animated:YES];
    }
}


//MARK: player

- (NSURL *)videoURL: (NSURL*)fileURL {
    return [self createHardLinkToVideoFile: fileURL];
}

//returns a hard link, so as not to maintain another copy of the video file on the disk
- (NSURL *)createHardLinkToVideoFile: (NSURL*)fileURL {
    NSError *err;
    NSURL* hardURL = [fileURL URLByAppendingPathExtension:@"mp4"];
    if (![hardURL checkResourceIsReachableAndReturnError:nil]) {
        if (![[NSFileManager defaultManager] linkItemAtURL: fileURL toURL: hardURL error:&err]) {
            // if creating hard link failed it is still possible to create a copy of self.asset.fileURL and return the URL of the copy
        }
    }
    return hardURL;
}

-(void) didPlayToEnd:(NSNotification*)notification{
    [self.player seekToTime:kCMTimeZero];
    if(self.isViewVisible){
        [self.player play];
    }
}


-(void) adjustVideoFrame{
    self.videoHeightConstraint.constant = self.view.frame.size.width * self.videoStream.height / self.videoStream.width;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &_payerItemContext) {
        dispatch_async(dispatch_get_main_queue(),^{
            if ((self.player.currentItem != nil) &&
                ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
                if(self.isViewVisible){
                    [self.activityIndicator stopAnimating];
                    [self.player play];
                }
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}


-(void)readyLoadingVideo: (CKAsset*)videoAsset{
    NSURL* viedoURL = [self videoURL:videoAsset.fileURL];
    AVAsset* asset = [AVAsset assetWithURL:viedoURL];
    NSArray* assetKeys = @[@"playable", @"hasProtectedContent"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(didPlayToEnd:) name:@"AVPlayerItemDidPlayToEndTimeNotification" object:nil];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset: asset automaticallyLoadedAssetKeys:assetKeys];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew  context: &_payerItemContext];
    // Associate the player item with the player
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    self.playerView.player = self.player;
}



-(void)resetPlayer{
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&_payerItemContext];
    [self.player pause];
}

@end
