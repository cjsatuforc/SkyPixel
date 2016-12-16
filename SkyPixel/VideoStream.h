//
//  VideoStream.h
//  SkyPixel
//
//  Created by Xie kesong on 12/10/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "User.h"

@interface VideoStream : NSObject

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) User* user;
@property (strong, nonatomic) CLLocation* location;
@property (strong, nonatomic) NSURL* url;
@property (nonatomic) NSInteger live;

- (id)init: (NSString*)title broadcastUser: (User*)user videoStreamUrl: (NSURL*)url streamLocation: (CLLocation*) location isLive: (NSInteger)live;

- (BOOL) isLive;
@end
