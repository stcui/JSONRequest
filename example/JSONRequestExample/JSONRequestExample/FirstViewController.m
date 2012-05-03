//
//  FirstViewController.m
//  JSONRequestExample
//
//  Created by stcui on 12-5-2.
//  Copyright (c) 2012年 stcui. All rights reserved.
//

#import "FirstViewController.h"
#import "JSONRequest.h"
#import "Descriptor.h"

@interface FirstViewController () <JSONRequestDelegate>
@property (strong, nonatomic) NSMutableArray *requests;
@property NSInteger requestCount;
@property (strong, nonatomic) NSDate *startDate;
@end

@implementation FirstViewController
@synthesize requests = _requests;
@synthesize requestCount = _requestCount;
@synthesize startDate = _startDate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        self.requests = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"run" style:UIBarButtonItemStyleBordered target:self action:@selector(run:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear" style:UIBarButtonItemStyleBordered target:self action:@selector(clear:)];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.requests.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * const identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    id obj = [self.requests objectAtIndex:indexPath.row];
    cell.textLabel.text = [obj description];
    cell.textLabel.textColor = [obj isKindOfClass:[NSDate class]] ? [UIColor greenColor] : [UIColor blueColor];
    return cell;
}

#pragma mark - Action
- (void)run:(id)sender
{
    self.startDate = [NSDate date];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.requestCount = 10;
    for (int i = 0; i < 10; ++i) {
        JSONRequest *request = [JSONRequest requestWithURL:[NSURL URLWithString:@"http://localhost:4567"]];
        request.delegate = self;
        [request send];
        @synchronized(self.requests) {
            [self.requests addObject:request];
        }
    }
    [self.tableView reloadData];
}

- (void)clear:(id)sender
{
    [self.requests removeAllObjects];
    [self.tableView reloadData];
}

- (void)updateUI
{
    [self.tableView reloadData];
    if (self.requestCount == 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        self.title = [NSString stringWithFormat:@"%lf", -[self.startDate timeIntervalSinceNow]];
    }
}
#pragma mark - JSONRequestDelegate
- (void)requestFinished:(JSONRequest *)request
{
    @synchronized(self.requests) {
        NSInteger index = [self.requests indexOfObject:request];
        if (index == NSNotFound) return;
        [self.requests replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble: -[request.sentDate timeIntervalSinceNow]]];
        -- self.requestCount;
    }
    [self updateUI];
}

- (void)requestFailed:(JSONRequest *)request
{
    @synchronized(self.requests) {
        NSInteger index = [self.requests indexOfObject:request];
        if (index == NSNotFound) return;
        [self.requests replaceObjectAtIndex:index withObject:[NSNumber numberWithDouble: -[request.sentDate timeIntervalSinceNow]]];
        -- self.requestCount;
    }
    [self updateUI];
}


@end
