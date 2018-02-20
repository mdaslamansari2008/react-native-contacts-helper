//
//  RCTContactHelperIOS.m
//  RCTContactHelperIOS
//
//  Created by aslam on 20/02/18.
//  Copyright © 2018 aslam. All rights reserved.
//

#import "RCTContactHelperIOS.h"

@implementation RCTContactHelperIOS

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(getValue:(NSString *)input callback:(RCTResponseSenderBlock)callback){
    NSLog(input);
    callback(@[@"Error filed", @"Result section"]);
}


@end
