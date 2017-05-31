//
//  ViewController.m
//  TestBottomSheet
//
//  Created by Daniele Maiorana on 30/05/17.
//  Copyright © 2017 Daniele Maiorana. All rights reserved.
//

#import "ViewController.h"
#import "DMBottomSheetViewController.h"
#import "TestViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (IBAction)btnOpen:(id)sender
{
    TestViewController *test = [[TestViewController alloc] initWithNibName:@"TestViewController" bundle:nil];
    test.view.frame = CGRectMake(0, 0, test.view.frame.size.width, 1200);
    test.title = @"Povina";
    DMBottomSheetViewController *bottom = [[DMBottomSheetViewController alloc] initWithRootViewController:test];
    [bottom presentInParentController:self];
    //[self presentViewController:test animated:NO completion:nil];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
