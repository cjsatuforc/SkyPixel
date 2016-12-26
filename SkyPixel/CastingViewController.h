//
//  CastingViewController.h
//  SkyPixel
//
//  Created by Xie kesong on 12/12/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoStream.h"
#import "User.h"


@interface CastingViewController : UIViewController<UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) VideoStream* videoStream;

@end
