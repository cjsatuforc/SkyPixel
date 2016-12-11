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

static double const LocationDegree = 0.05;
static NSString* const NavigationBarTitleFontName = @"Avenir-Heavy";
static CGFloat const NavigationBarTitleFontSize = 17;
static NSString* const MapViewReuseIdentifier = @"AnnotationViweIden";

//static double const Latitude = 32.88831721994364;
//static double const Longitude = -117.2413945199151;
//static double const Latitude2 = 32.905528;
//static double const Longitude2 = -117.242703;
static NSString* const email1 = @"JohnApp@skypixel.com";

@interface SkyCastViewController () <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSMutableArray* photos;

@property (strong, nonatomic) CLLocationManager* locationManager;


- (CKAsset*) getCKAssetFromFileName: (NSString*)filename withExtension:(NSString*)ext inDirectory: (NSString*)dir;

- (void) fetchDataForUser: (CKRecord*)user;

- (void) createUser;


@end

@implementation SkyCastViewController

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
    }
    
}

- (void) createUser{
    //create a user
    CKRecord* user = [[CKRecord alloc] initWithRecordType:@"user"];
    user[@"fullname"] = @"Johnny Appleseed";
    user[@"email"] = email1;
    user[@"avator"] = [self getCKAssetFromFileName:@"avator1" withExtension:@"jpg" inDirectory:@"avator"];
    CKDatabase* publicDb = [[CKContainer defaultContainer] publicCloudDatabase];
    [publicDb saveRecord:user completionHandler:^(CKRecord* record, NSError* error){
        if(error == nil){
            [self fetchDataForUser:record];
        }else{
            NSLog(@"%@", error.localizedDescription);
        }
    }];

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

- (void) fetchDataForUser: (CKRecord*)user {
    //fetch
//    CKDatabase* publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
//    NSString* emailAttrName = @"email";
//    NSString* email = email1;
//    NSPredicate* predicate = [NSPredicate predicateWithFormat: @" %K = %@", emailAttrName, email];
//    CKQuery* query = [[CKQuery alloc] initWithRecordType:@"user" predicate: predicate];
//    
    //get the first record that matches
    if(user){
        //create a videostream record
        CKRecord* videoStreamRecord = [[CKRecord alloc] initWithRecordType:@"videostream"];
        videoStreamRecord[@"title"] = @"Aerial Shots of Sedona Arizona";
        CLLocation* location = [[CLLocation alloc] initWithLatitude:32.88831721994364 longitude: -117.2413945199151];
        videoStreamRecord[@"location"] = location;
        videoStreamRecord[@"live"] = [[NSNumber alloc] initWithInt:0];
        videoStreamRecord[@"user"] = [[CKReference alloc] initWithRecord:user action:CKReferenceActionDeleteSelf];
        videoStreamRecord[@"video"] = [self getCKAssetFromFileName:@"clip1" withExtension:@"mp4" inDirectory:@"clip"];
        CKDatabase* publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
        [publicDB saveRecord:videoStreamRecord completionHandler:^(CKRecord* record, NSError* error){
            if(error == nil){
                NSLog(@"%@", record);
            }else{
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
}


//MARK: - UPATE UI
- (void) updateUI{
    [self.navigationController.navigationBar setBarTintColor: [UIColor blackColor]];
    UIFont* titleFont = [UIFont fontWithName: NavigationBarTitleFontName size: NavigationBarTitleFontSize];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: titleFont,    NSForegroundColorAttributeName: [UIColor whiteColor]}];
}

- (UIStatusBarStyle) preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
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
        MKCoordinateRegion region = MKCoordinateRegionMake(currentLocation.coordinate, MKCoordinateSpanMake(LocationDegree, LocationDegree));
        [self.mapView setRegion:region];
        [manager stopUpdatingLocation];
    }
}


//MARK: - MKMapViewDelegate
-(MKAnnotationView*) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if([annotation isKindOfClass:[ MKUserLocation class]]){
        return nil;
    }
    MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier: MapViewReuseIdentifier];
    if(!annotationView){
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:MapViewReuseIdentifier];
    }else{
        annotationView.annotation = annotation;
    }
    
    
    
    
    
//    NSString* thumbnailUrl = ((User*)annotation).;
//    UIImage* image = [UIImage imageNamed: thumbnailUrl];
//    annotationView.image = image;
//    annotationView.frame = CGRectMake(0, 0, 48, 48);
//    annotationView.layer.borderColor = [[UIColor whiteColor] CGColor];
//    annotationView.layer.borderWidth = 2.0;
//    annotationView.layer.cornerRadius = 4.0;
//    annotationView.clipsToBounds = YES;
    return annotationView;
}

@end
