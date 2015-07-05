//
//  KADMutualExclusive.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADMutualExclusive.h"
#import <UIKit/UIViewController.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIAlert.h>

@interface KADMutualExclusive ()
{
    
}
@property (nonatomic, strong) NSString * className;
@end

@implementation KADMutualExclusive
//+(instancetype)remoteNotificationPermissionMutex
//{
//    return [KADMutualExclusive mutualExclusiveForClass:[]];
//}
+(instancetype)alertMutex
{
    return [KADMutualExclusive mutualExclusiveForClass:[UIAlertController class]];
}
+(instancetype)viewControllerMutex
{
    return [KADMutualExclusive mutualExclusiveForClass:[UIViewController class]];
}
+(instancetype)mutualExclusiveForClass:(Class)class
{
    KADMutualExclusive * mutex = [[KADMutualExclusive alloc] init];
    mutex.className = NSStringFromClass(class);
    return mutex;
}

#pragma mark - SUBCLASSING
-(NSString *)name
{
    return [NSString stringWithFormat:@"MutuallyExclusive<%@>", self.className];
}
-(BOOL)isMutuallyExclusive
{
    return YES;
}
-(NSOperation *)dependencyForOperation:(KADOperation *)operation
{
    return nil;
}
-(void)evaluateForOperation:(KADOperation *)operation completion:(void (^)(KADOperationConditionResult *))completion
{
    completion([KADOperationConditionResult satisfied]);
}
@end
