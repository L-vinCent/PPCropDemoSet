//
//  ViewController.m
//  PPCropTest
//
//  Created by Liao PanPan on 2018/4/3.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "ViewController.h"
#import "PPCropMainVC.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}


- (IBAction)eventClick:(id)sender {
    
    PPCropMainVC *vc = [[PPCropMainVC alloc]initWithImage:[UIImage imageNamed:@"1.png"]];
    [self.navigationController pushViewController:vc animated:YES];
    
    
    
    vc.cropBlock = ^(UIImage *image) {
        
        self.mainImageView.image = image;
        
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
