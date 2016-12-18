//
//  ExploreSearchTableViewController.m
//  SkyPixel
//
//  Created by Xie kesong on 12/15/16.
//  Copyright © 2016 ___KesongXie___. All rights reserved.
//

#import "ExploreSearchTableViewController.h"
#import "ExploreSearchTableViewCell.h"

@interface ExploreSearchTableViewController()

@property (strong, nonatomic) UISearchController* searchController;

@property (nonatomic) BOOL viewShouldExpand;

@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (nonatomic) BOOL isKeyBoardVisible;

@property (strong, nonatomic) NSArray<CLPlacemark *> * placeMarks;

@property (nonatomic) BOOL didUserStartTyping;

-(void)expandHeaderView;

-(void)collapseHeaderView;

-(void)showSkyCastMapView;

@end

@implementation ExploreSearchTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.definesPresentationContext = YES;
    self.navigationController.navigationBar.barTintColor = [[UIColor alloc]initWithRed:236/255.0 green:236/255.0 blue:236/255.0 alpha:1];
    self.searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.hidesNavigationBarDuringPresentation = false;
    self.searchController.searchBar.placeholder = @"Enter a spot";
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.keyboardAppearance = UIKeyboardAppearanceLight;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.tintColor = [[UIColor alloc]initWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1];
    self.searchController.searchBar.translucent = NO;
    self.navigationItem.titleView = self.searchController.searchBar;
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(searchIconTapped:) name:@"SearchIconTapped" object:nil];
}

-(void) viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if(!self.isKeyBoardVisible){
        [self expandHeaderView];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

-(void)expandHeaderView{
    [self.headerView setHidden:NO];
    CGSize size = self.view.frame.size;
    CGFloat headerViewWidth = size.width;
    CGFloat headerViewHeight = size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
    self.headerView.frame = CGRectMake(0, 0, headerViewWidth, headerViewHeight);
}

-(void) searchIconTapped: (NSNotification*) notification{
    [self.searchController.searchBar becomeFirstResponder];
}


-(void)collapseHeaderView{
    [self.headerView setHidden:YES];
    self.headerView.frame = CGRectMake(0, 0, self.headerView.frame.size.width, 0);
}

-(void)showSkyCastMapView{
    ContainerViewController* containerVC = (ContainerViewController*)self.parentViewController.parentViewController;
    [containerVC bringMainViewToFront];
    [self expandHeaderView];
    [self.searchController.searchBar resignFirstResponder];
    self.searchController.searchBar.text = @"";
    self.placeMarks = nil;
    [self.tableView reloadData];
    self.didUserStartTyping = NO;
}

//MARK - UITableViewDelegate, UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.placeMarks.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExploreSearchCell" forIndexPath:indexPath];
    if([cell isKindOfClass:[ExploreSearchTableViewCell class]]){
        ExploreSearchTableViewCell* searchCell = (ExploreSearchTableViewCell*)cell;
        [searchCell setPlaceMark:self.placeMarks[indexPath.row]];
        return searchCell;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CLPlacemark* placeMark = self.placeMarks[indexPath.row];
    //bring the bottom to the top
    CLLocation* location = placeMark.location;
    //post a notification back to the skycastvc and set the new location
    NSDictionary* userInfo = @{@"location": location, @"title": placeMark.name, @"subTitle": [ExploreSearchTableViewCell getAddressFromPlaceMark:placeMark]};
    
    NSNotification* notification = [[NSNotification alloc] initWithName:@"LocationSelected" object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    [self showSkyCastMapView];
}


//MARK: - UISearchResultsUpdating protocol
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    if(self.didUserStartTyping){
        [self collapseHeaderView];
        CLGeocoder* geoCoder = [[CLGeocoder alloc]init];
        [geoCoder geocodeAddressString:self.searchController.searchBar.text
     completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             self.placeMarks = placemarks;
             [self.tableView reloadData];
         });
     }];
    }
}


//MARK: - UISearchBarDelegate
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    self.isKeyBoardVisible = YES;
    CGPoint newPoint = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + 60);
    [UIView animateWithDuration:0.3f animations:^{
        self.tableView.contentOffset = newPoint;
    }];
    return YES;
}


-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    self.isKeyBoardVisible = NO;
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    if([self.parentViewController.parentViewController isKindOfClass:[ContainerViewController class]]){
        [self showSkyCastMapView];
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    self.didUserStartTyping = YES;
}

@end
