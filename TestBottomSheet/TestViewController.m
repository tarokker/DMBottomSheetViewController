//
//  TestViewController.m
//  TestBottomSheet
//
//  Created by Daniele Maiorana on 30/05/17.
//  Copyright © 2017 Daniele Maiorana. All rights reserved.
//

#import "TestViewController.h"
#import "DMBottomSheetViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (IBAction)btnClick:(id)sender
{
    NSLog(@"DECRI");
}

- (IBAction)btnCloseclick:(id)sender
{
    [self.dmBottomSheetViewController close:YES withCompletion:nil];
}

@end
