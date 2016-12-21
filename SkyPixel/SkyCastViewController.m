//
//  SkyCastViewController.m
//  SkyPixel
//
//  Created by Xie kesong on 12/4/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CloudKit/CloudKit.h>
#import "SkyCastViewController.h"
#import "VideoStream+Annotation.h"
#import "PlayView.h"
#import "CastingViewController.h"
#import "ContainerViewController.h"

static double const LocationDegree = 0.05;
static NSString* const NavigationBarTitleFontName = @"Avenir-Heavy";
static CGFloat const NavigationBarTitleFontSize = 17;
static NSString* const MapViewReuseIdentifier = @"AnnotationViweIden";
static NSString* const ShowCastingSegueIdentifier = @"ShowCasting";
static NSString* const email1 = @"kesongxie@skypixel.com";
static CGFloat const searchRadius = 10000; //load video within 10 km from the locationCenter

@interface SkyCastViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableArray* photos;
@property (strong, nonatomic) CLLocationManager* locationManager;
@property (strong, nonatomic) NSMutableArray<VideoStream*>* videoStreamAnnotations;
@property (strong, nonatomic) AVAsset* asset;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) PlayerView* playerView;
@property (strong, nonatomic) NSString* payerItemContext;
@property (strong, nonatomic) UISearchController* searchController;
@property (strong, nonatomic) CLLocation* locationCenter; //the surrounding footage will be loaded
@property (nonatomic) BOOL isFetchingRecord;

//create a video stream record
- (CKRecord*) getVideoStreamRecord: (NSString*)title fromLocation: (CLLocation*)location isLive: (NSInteger)live whoShot: (CKReference*)user clipAsset: (CKAsset*) asset;

//create a asset from file info
- (CKAsset*) getCKAssetFromFileName: (NSString*)filename withExtension:(NSString*)ext inDirectory: (NSString*)dir;

- (void) fetchLive;

- (void) createEntries;


// Load video and play
// **Make sure the asset and playerView of the view controller is set**
- (void) prepareToPlay;

- (void)removeHardLinkToVideoFile: (NSURL*)fileURL;

@end

@implementation SkyCastViewController

- (IBAction)searchIconTapped:(UIBarButtonItem *)sender {
    if([self.parentViewController.parentViewController isKindOfClass:[ContainerViewController class]]){
        ContainerViewController* containerVC = (ContainerViewController*)self.parentViewController.parentViewController;
        [containerVC bringExploreViewToFront];
        NSNotification* notification = [[NSNotification alloc]initWithName:@"SearchIconTapped" object:self userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (IBAction)backFromCastingViewController:(UIStoryboardSegue *)segue {
    [self.player play];
}

- (IBAction)searchBtnTapped:(UIBarButtonItem *)sender {
    if([self.parentViewController.parentViewController isKindOfClass: [ContainerViewController class]]){
        ContainerViewController* containerVC = (ContainerViewController*)self.parentViewController.parentViewController;
        [containerVC toggleLeftMainView];
    }
}



- (void) viewDidLoad{
    [super viewDidLoad];
    [self updateUI];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
        [self.locationManager startUpdatingLocation];
      //  [self createEntries];

    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(didPlayToEnd:) name:@"AVPlayerItemDidPlayToEndTimeNotification" object:nil];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(locationDidSelected:) name:@"LocationSelected" object:nil];
}


-(void) didPlayToEnd:(NSNotification*)notification{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}


-(void) locationDidSelected:(NSNotification*)notification{
    CLLocation* location = (CLLocation*)notification.userInfo[@"location"];
    if(location != nil){
        //update
        dispatch_async(dispatch_get_main_queue(), ^{
            MKPointAnnotation* spotAnnotation = [[MKPointAnnotation alloc] init];
            [spotAnnotation setCoordinate:location.coordinate];
            NSString* title = (NSString*)notification.userInfo[@"title"];
            if(title != nil){
                spotAnnotation.title = title;
                NSString* subTitle = (NSString*)notification.userInfo[@"subTitle"];
                if(subTitle != nil){
                    spotAnnotation.subtitle = subTitle;
                }
            }
            self.locationCenter = location;
            [self.mapView addAnnotation:spotAnnotation];
            MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(LocationDegree, LocationDegree));
            [self.mapView setRegion:region];
            //fetch live
            [self fetchLive];
        });
    }else{
        NSLog(@"location is nil");
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


-(BOOL)hidesBottomBarWhenPushed {
    return YES;
}

//this is called to initilize the icloud storage with preset data
-(void) createEntries{
    //create a user
    CKRecord* user = [[CKRecord alloc] initWithRecordType:@"user"];
    user[@"fullname"] = @"Kesong Xie";
    user[@"email"] = email1;
    user[@"avator"] = [self getCKAssetFromFileName:@"avator1" withExtension:@"png" inDirectory:@"avator"];
    CKDatabase* publicDb = [[CKContainer defaultContainer] publicCloudDatabase];
    [publicDb saveRecord:user completionHandler:^(CKRecord* record, NSError* error){
        if(error == nil){
            CKRecord* user = record;
                if(user){
                    //create a videostream record
                    //paris
                    CKRecord* videoStreamRecord1 = [self getVideoStreamRecord: @"Eiffel Tower Paris" fromLocation:[[CLLocation alloc] initWithLatitude:48.857610 longitude: 2.294083] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip1" withExtension:@"mp4" inDirectory:@"clip"]];
                    CKRecord* videoStreamRecord2 = [self getVideoStreamRecord: @"Paris Skyline View Of The City and Eiffel Tower From The Arc De Triomphe" fromLocation:[[CLLocation alloc] initWithLatitude:48.857697 longitude: 2.297494] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip2" withExtension:@"mp4" inDirectory:@"clip"]];
                    
                    //shenzhen
                    CKRecord* videoStreamRecord3 = [self getVideoStreamRecord: @"DJI - Phantom 4 China Launch" fromLocation:[[CLLocation alloc] initWithLatitude:22.543096 longitude: 114.057865] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip3" withExtension:@"mp4" inDirectory:@"clip"]];
                    
                    //ucsd
                    CKRecord* videoStreamRecord4 = [self getVideoStreamRecord: @"UCSD, Torrey Pines, Sunset Cliffs From Above" fromLocation:[[CLLocation alloc] initWithLatitude:32.880334 longitude: -117.245793] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip4" withExtension:@"mp4" inDirectory:@"clip"]];
                   
                    
                    CKRecord* videoStreamRecord5 = [self getVideoStreamRecord: @"Geisel Library Drone - UCSD - University of California San Diego" fromLocation:[[CLLocation alloc] initWithLatitude:32.881019 longitude: -117.237827] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip5" withExtension:@"mp4" inDirectory:@"clip"]];
                    
                    
                    CKRecord* videoStreamRecord6 = [self getVideoStreamRecord: @"Winter at Stanford University recording with drone" fromLocation:[[CLLocation alloc] initWithLatitude:37.427517 longitude: -122.170233] isLive:1 whoShot:[[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf] clipAsset:[self getCKAssetFromFileName:@"clip6" withExtension:@"mp4" inDirectory:@"clip"]];
                    
                    
                    NSArray<CKRecord*>* recordToBeSaved = @[videoStreamRecord1, videoStreamRecord2, videoStreamRecord3, videoStreamRecord4, videoStreamRecord5, videoStreamRecord6];
                    
                    //configure the CKModifyRecordsOperation and save multiple records
                    CKDatabase* publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
                    CKModifyRecordsOperation* saveOperation = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordToBeSaved recordIDsToDelete:nil];
                    saveOperation.database = publicDB;
                    saveOperation.atomic = NO;
                    saveOperation.modifyRecordsCompletionBlock = ^(NSArray<CKRecord *> *savedRecords, NSArray<CKRecordID *> *deletedRecordIDs, NSError *operationError){
                        NSLog(@"%@", savedRecords);
                    };
                    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
                    
                    //save records
                    [operationQueue addOperation:saveOperation];
                }
        }else{
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (CKRecord*) getVideoStreamRecord: (NSString*)title fromLocation: (CLLocation*)location isLive: (NSInteger)live whoShot: (CKReference*)user clipAsset: (CKAsset*) asset  {
    CKRecord* videoStreamRecord = [[CKRecord alloc] initWithRecordType:@"videostream"];
    videoStreamRecord[@"title"] = title;
    videoStreamRecord[@"location"] = location;
    videoStreamRecord[@"live"] = [[NSNumber alloc] initWithInt:live];
    videoStreamRecord[@"user"] = user;
    videoStreamRecord[@"video"] = asset;
    return videoStreamRecord;
}


- (CKAsset*) getCKAssetFromFileName: (NSString*)filename withExtension:(NSString*)ext inDirectory: (NSString*)dir{
    NSString* pathname = [[NSBundle mainBundle] pathForResource:filename ofType: ext inDirectory:dir];
    if(pathname){
        NSURL* url = [[NSURL alloc] initFileURLWithPath:pathname];
        if(url){
            CKAsset* asset = [[CKAsset alloc] initWithFileURL:url];
            return asset;
        }
    }
    return nil;
}

- (void) fetchLive {
    if(self.isFetchingRecord){
        return;
    }
    //start loading drone flying user
    CKDatabase* publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", self.locationCenter, searchRadius];
    CKQuery* query = [[CKQuery alloc] initWithRecordType:@"videostream" predicate: predicate];
    self.navigationItem.title = @"SEARCHING...";
    self.isFetchingRecord = YES;
    [publicDB performQuery:query inZoneWithID:nil completionHandler:^(NSArray<CKRecord*>* videoStreamRecords, NSError* error){
        if(error == nil){
            if(videoStreamRecords){
                self.videoStreamAnnotations = [[NSMutableArray alloc]init];
                __block NSInteger userFetchedCompletedCount = 0;
                for(CKRecord* streamRecord in videoStreamRecords){
                    VideoStream* videoStream = [[VideoStream alloc]initWithCKRecord:streamRecord];
                    [videoStream fetchUserForVideoStream:^(CKRecord *userRecord, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.videoStreamAnnotations insertObject:videoStream atIndex:0];
                            [self.mapView addAnnotations: self.videoStreamAnnotations];
                            userFetchedCompletedCount = userFetchedCompletedCount + 1;
                            if(userFetchedCompletedCount == videoStreamRecords.count){
                                //The fetching for all the users are now completed
                                self.navigationItem.title = @"SKYCAST";
                                self.isFetchingRecord = NO;
                            }
                        });
                    }];
                }
            }
        }else{
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


//MARK: - UPATE UI
- (void) updateUI{
    [self.navigationController.navigationBar setBarTintColor: [UIColor blackColor]];
    UIFont* titleFont = [UIFont fontWithName: NavigationBarTitleFontName size: NavigationBarTitleFontSize];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: titleFont,    NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

//MARK: - Audio player
-(UIImage *)generateThumbImage : (NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = kCMTimeZero;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *originImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    UIImage* squareImage = [self cropSquareFromImage:originImage];
    return squareImage;
}

-(UIImage *) cropSquareFromImage : (UIImage *)image{
    CGFloat idealLengthOfSuqare = (image.size.width > image.size.height) ? image.size.height : image.size.width;
    CGSize squareSize = CGSizeMake(idealLengthOfSuqare, idealLengthOfSuqare);
    UIGraphicsBeginImageContextWithOptions(squareSize, YES, 1.0);
    
    CGRect drawRect = CGRectMake(0, 0, idealLengthOfSuqare, idealLengthOfSuqare);
    [image drawInRect:drawRect];
    UIImage* suqreImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return suqreImage;
}

- (void) prepareToPlay {
    // Create a new AVPlayerItem with the asset and an
    // array of asset keys to be automatically loaded
    NSArray* assetKeys = @[@"playable", @"hasProtectedContent"];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset automaticallyLoadedAssetKeys:assetKeys];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew  context: &_payerItemContext];
    // Associate the player item with the player
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    [self.player setMuted:YES];
    self.playerView.player = self.player;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &_payerItemContext) {
        dispatch_async(dispatch_get_main_queue(),^{
            if ((self.player.currentItem != nil) &&
                ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
                [self.player play];
            }
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
    
}


-(void)resetPlayer{
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&_payerItemContext];
    [self.player pause];
}

//get the valid videoURL for asisgning to the AVAsset, the icound fileURL is not a valid url
//because it does not contain a extension
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

//The paramter fileURL is the CKAsset fileURL
- (void)removeHardLinkToVideoFile: (NSURL*)fileURL {
    NSError *err;
    NSURL* hardURL = [fileURL URLByAppendingPathExtension:@"MP4"];
    if ([hardURL checkResourceIsReachableAndReturnError:nil]) {
        if (![[NSFileManager defaultManager] removeItemAtURL:hardURL error:&err]) {
        }
    }
}

//MARK: - Prepare for segue
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [self.player pause];
    if([sender isKindOfClass:[MKAnnotationView class]]){
        if([segue.identifier isEqualToString:ShowCastingSegueIdentifier]){
            if([segue.destinationViewController isKindOfClass:[CastingViewController class]]){
                CastingViewController* destinationVC = segue.destinationViewController;
                destinationVC.asset = self.asset;
                VideoStream* videoStream = ((MKAnnotationView*)sender).annotation;
                destinationVC.videoStream = videoStream;
                destinationVC.user = videoStream.user;
            }
        }
    }
}

//MARK: - CLLocationManagerDelegate
-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
        [manager startUpdatingLocation];
    }else{
        NSLog(@"Location not authorized");
    }
}

-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    if([locations count] > 0){
        CLLocation* currentLocation = locations.lastObject;
        self.locationCenter = currentLocation;
        MKCoordinateRegion region = MKCoordinateRegionMake(currentLocation.coordinate, MKCoordinateSpanMake(LocationDegree, LocationDegree));
        [self.mapView setRegion:region];
        [self fetchLive];
        [manager stopUpdatingLocation];
    }
}


//MARK: - MKMapViewDelegate
-(MKAnnotationView*) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if([annotation isKindOfClass:[ MKUserLocation class]]){
        return nil;
    }else if([annotation isKindOfClass:[ MKPointAnnotation class]]){
        return nil;
    }
    MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier: MapViewReuseIdentifier];
    if(!annotationView){
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MapViewReuseIdentifier];
    }else{
        annotationView.annotation = annotation;
    }
    VideoStream* videoStream = (VideoStream*)annotation;
    annotationView.image = [self generateThumbImage:[self videoURL:videoStream.url]];
    annotationView.frame = CGRectMake(0, 0, 60, 60);
    annotationView.layer.borderColor = [[UIColor whiteColor] CGColor];
    annotationView.layer.borderWidth = 2.0;
    annotationView.canShowCallout = YES;
    
    if([videoStream isLive]){
        //add overlay
        UIView* overlayView = [[UIView alloc]initWithFrame:annotationView.frame];
        overlayView.backgroundColor = [UIColor blackColor];
        overlayView.alpha = 0.1;
        [annotationView addSubview:overlayView];
        //add video icon
        UIImage* liveIcon = [UIImage imageNamed:@"live-icon"];
        UIImageView* liveIconImageView = [[UIImageView alloc] initWithImage:liveIcon];
        liveIconImageView.frame = CGRectMake(36, 6, 18, 14);
        [annotationView addSubview:liveIconImageView];
    }

    return annotationView;
}

-(void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    if([view.annotation isKindOfClass:[VideoStream class]]){
        //configure left callout accessory view
        VideoStream* videoStream = (VideoStream*)view.annotation;
        NSURL* viedoURL = [self videoURL:videoStream.url];
        AVAsset* asset = [AVAsset assetWithURL:viedoURL];
        self.asset = asset;
        CGSize footageSize = self.asset.tracks.firstObject.naturalSize;
        CGRect frame = CGRectMake(0, 0, (49.0 * footageSize.width / footageSize.height), 49.0);
        self.playerView = [[PlayerView alloc] initWithFrame:frame];
        self.playerView.backgroundColor = [UIColor blackColor];
        view.leftCalloutAccessoryView = self.playerView;
        
        //configure right callout accessory view and btn
        UIImage* arrowIcon = [UIImage imageNamed:@"arrow-icon"];
        UIButton* disclosureBtn = [[UIButton alloc]init];
        [disclosureBtn sizeToFit];
        [disclosureBtn setBackgroundImage:arrowIcon forState:UIControlStateNormal];
        view.rightCalloutAccessoryView = disclosureBtn;
        
        [self prepareToPlay];
    }
}

-(void) mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
     if([view.annotation isKindOfClass:[VideoStream class]]){
         [self resetPlayer];
     }
};

-(void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    [self performSegueWithIdentifier:ShowCastingSegueIdentifier sender: view];
}

@end

