//
//  YHForInstructionsViewController.m
//  YHCustomer
//
//  Created by wangliang on 15-1-8.
//  Copyright (c) 2015年 富基融通. All rights reserved.
//  抢购说明

#import "YHForInstructionsViewController.h"

@interface YHForInstructionsViewController ()

@end

@implementation YHForInstructionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"抢购说明";
    self.navigationItem.leftBarButtonItems = BACKBARBUTTON(@"返回", @selector(back:));
    [self addWebView];
    [self loadRequest];

}
-(void)addWebView
{
//    if (IOS_VERSION >= 7) {
//        webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, ScreenSize.width, ScreenSize.height)];
//    }else{
//        webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, ScreenSize.width, ScreenSize.height)];
//    }
    if (IOS_VERSION >= 7) {
        webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, ScreenSize.width, ScreenSize.height)];
    }else{
        webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, NAVBAR_HEIGHT, ScreenSize.width, ScreenSize.height - NAVBAR_HEIGHT)];
    }
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    webView.backgroundColor = LIGHT_GRAY_COLOR;
    [self.view addSubview:webView];
}
-(void)loadRequest
{
    //v1/page/service_info?type=6
    url = [NSString stringWithFormat:@"%@v1/page/service_info?type=6",BASE_URL];
    NSMutableURLRequest *requsetObj = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [requsetObj setValue:[ASIHTTPRequest defaultUserAgentString] forHTTPHeaderField:@"User-Agent"];
    
    [webView loadRequest:requsetObj];
}
-(void)back:(id)button
{
    [self.navigationController popViewControllerAnimated:YES];
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

@end