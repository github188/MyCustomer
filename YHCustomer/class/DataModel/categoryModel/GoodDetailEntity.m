//
//  GoodDetailEntity.m
//  THCustomer
//
//  Created by lichentao on 13-10-21.
//  Copyright (c) 2013年 efuture. All rights reserved.
//

#import "GoodDetailEntity.h"

@implementation GoodDetailEntity

@synthesize alias,details,photo;
@synthesize  page_url;
@synthesize title,description;

@end


@implementation GoodDetailNetTransobj
/*
- (BOOL)requestFailed:(ASIHTTPRequest *)request
{
    if(![super requestFailed:request])
    {
        return NO;
    }
    
    NSLog(@"request fail");
    
    if([request isCancelled])
    {
        NSLog(@"request cancel");
    }
    [_uinet requestFailed:self._nApiTag withStatus:WEB_STATUS_0 withMessage:@"网络不给力，请稍后重试！"];
    [[NetTrans getInstance]cancelRequest:self];
    return YES;
}

-(BOOL) responseSuccess:(ASIHTTPRequest *)request{
    
    if(![super responseSuccess:request])
    {
        return NO;
    }
    NSData * myResponseData = [request responseData];
	NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingUTF8);//kCFStringEncodingUTF8
	NSString * myResponseStr = [[NSString alloc] initWithData:myResponseData encoding:enc];
    NSDictionary  *jsonDic = [myResponseStr objectFromJSONString];
    
    //返回结果是以Dictionary存在
    NSString *status = [NSString stringWithFormat:@"%@",[jsonDic objectForKey:@"status"]];
    NSArray *dicArray = [jsonDic objectForKey:@"data"];
    NSDictionary *dic = [dicArray objectAtIndex:0];
    if([status isEqualToString:WEB_STATUS_1] ){
        // 封装商品详情分享数据
        GoodDetailEntity *buNearEntity = [[GoodDetailEntity alloc] init];
        buNearEntity.alias = [dic objectForKey:@"alias"];
        buNearEntity.details = [dic objectForKey:@"details"];
        buNearEntity.photo = [dic objectForKey:@"photo"];
        buNearEntity.page_url = [dic objectForKey:@"page_url"];
        buNearEntity.title = [dic objectForKey:@"title"];
        buNearEntity.description = [dic objectForKey:@"description"];
        
        if ([_uinet respondsToSelector:@selector(responseSuccessObj:nTag:)])
        {
            [_uinet responseSuccessObj:buNearEntity nTag:self._nApiTag];
        }
    }
    else{
        [_uinet requestFailed:self._nApiTag withStatus:WEB_STATUS_0 withMessage:[jsonDic objectForKey:@"message"]];
    }
    [[NetTrans getInstance]cancelRequest:self];
    
    return YES;
}
*/
-(void)request:(NSString *)request andDic:(NSDictionary *)dic
{
    if ([[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable)
    {
        if (_uinet && [_uinet respondsToSelector:@selector(requestFailed:withStatus:withMessage:)]) {
            [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:@"请检查网络连接！"];
        }
        return;
    }
    
    NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    
    NSMutableURLRequest *serializedRequest = [requestSerializer requestWithMethod:@"POST" URLString:request parameters:dic error:&error];
    if (error != nil) {
        if (_uinet && [_uinet respondsToSelector:@selector(requestFailed:withStatus:withMessage:)]) {
            [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:@"错误请求！"];
        }
    }
    [serializedRequest setTimeoutInterval:OUTTIME];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:serializedRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSString *base64String = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
         //        NSString *str = [SQAESDE deCryptBase64:base64String key:kTORKey];
         //        if (kTORDEBUG) {NSLog(@"%@",str);}
         
         if (!base64String)
         {
             [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:@"数据返回错误，请重新请求！"];
             return ;
         }
         
         NSError *error = nil;
         id jsonObject = [NSJSONSerialization JSONObjectWithData:[base64String dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
         
         if (!error && jsonObject)
         {
             NSLog(@"jsonObject = %@" , jsonObject);
             //            NSString *responseClass = [NSStringFromClass([request class]) replaceCharacter:@"Request" withString:@"Response"];
             //            _torResponse = [[NSClassFromString(responseClass) alloc] init];
             //            _torResponse = [_torResponse initWithDictionary:jsonObject];
             if (_uinet && [_uinet respondsToSelector:@selector(responseSuccessObj:nTag:)])
             {
                 NSString *status = [NSString stringWithFormat:@"%@",[jsonObject objectForKey:@"status"]];
                 NSString * message = [jsonObject objectForKey:@"message"];
                 
                 if ([status isEqualToString:@"0"])
                 {
                     [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:message];
                     return;
                 }
                 else if ([status isEqualToString:@"1"])
                 {
                     NSArray* datas = [jsonObject objectForKey:@"data"];
                     if (!datas || (datas == nil))
                     {
                         //                        [[NetTrans getInstance] cancelRequest:self];
                         [_uinet requestFailed:self._nApiTag withStatus:@"0" withMessage:@"网络请求错误"];
                         return ;
                     }
                     else
                     {
                         NSDictionary *dic = [datas objectAtIndex:0];
                         GoodDetailEntity *buNearEntity = [[GoodDetailEntity alloc] init];
                         buNearEntity.alias = [dic objectForKey:@"alias"];
                         buNearEntity.details = [dic objectForKey:@"details"];
                         buNearEntity.photo = [dic objectForKey:@"photo"];
                         buNearEntity.page_url = [dic objectForKey:@"page_url"];
                         buNearEntity.title = [dic objectForKey:@"title"];
                         buNearEntity.description = [dic objectForKey:@"description"];
                         [_uinet responseSuccessObj:buNearEntity nTag:self._nApiTag];
                         return;
                     }
                 }
                 else if ([status isEqualToString:WEB_STATUS_3])
                 {
                     [_uinet requestFailed:_nApiTag withStatus:WEB_STATUS_3 withMessage:message];
                     return;
                 }
                 else
                 {
                     [_uinet requestFailed:_nApiTag withStatus:status withMessage:message];
                     return;
                 }
             }
         }
         else
         {
            [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:[PublicMethod changeStr:error.localizedDescription]];         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (_uinet && [_uinet respondsToSelector:@selector(requestFailed:withStatus:withMessage:)])
         {
             //            [_delegate torNetwork:self didFailLoadWithError:error];
            [_uinet requestFailed:_nApiTag withStatus:@"0" withMessage:[PublicMethod changeStr:error.localizedDescription]];         }
         
     }];
    [operation start];
}
@end