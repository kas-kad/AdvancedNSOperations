//
//  KADRemoteNotificationsCondition.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADRemoteNotificationsCondition.h"
#import "KADOperationQueue.h"
#import <UIKit/UIApplication.h>
#import "KADMutualExclusive.h"
#import "NSError+KADOperationErrors.h"

NSString * kRemoteNotificationName = @"RemoteNotificationPermissionNotification";
static KADOperationQueue * _remoteNotificationQueue = nil;

/// A condition for verifying that the app has the ability to receive push notifications.
@interface KADRemoteNotificationsCondition ()
@property (nonatomic, strong) UIApplication * application;
@end
@implementation KADRemoteNotificationsCondition

+(void)didReceiveNotificationToken:(NSData *)token
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteNotificationName object:nil userInfo: @{ @"token": token }];
}

+(void)didFailToRegister:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kRemoteNotificationName object:nil userInfo: @{ @"error": error }];
}
-(instancetype)init:(UIApplication *)application {
    if (self = [super init]){
        _application = application;
        _remoteNotificationQueue = [KADOperationQueue new];
    }
    return self;
}

#pragma mark - Condition
-(NSString *)name
{
    return NSStringFromClass(self.class);
}
-(BOOL)isMutuallyExclusive
{
    return NO;
}
-(void)evaluateForOperation:(KADOperation *)operation
                 completion:(void (^)(KADOperationConditionResult *))completion
{
    /*
     Since evaluation requires executing an operation, use a private operation
     queue.
     */
    KADRemoteNotificationPermissionOperation * op = [[KADRemoteNotificationPermissionOperation alloc] initWithApplication:self.application handler: ^(KADRemoteRegistrationResult * result) {

        if (result.token){
            completion([KADOperationConditionResult satisfied]);
        } else if (result.error) {
            completion([KADOperationConditionResult failed:[NSError errorWithCode:KADConditionFailed
                         userInfo:@{
                                kOperationConditionKey: self.name,
                                  NSUnderlyingErrorKey: result.error
                                                            }]]);
        }
    }];
    [_remoteNotificationQueue addOperation: op];
}
-(NSOperation *)dependencyForOperation:(KADOperation *)operation
{
    return [[KADRemoteNotificationPermissionOperation alloc] initWithApplication:self.application handler:nil];
}
#pragma mark -
@end


@interface KADRemoteNotificationPermissionOperation ()
@property (nonatomic, strong) UIApplication * application;
@property (nonatomic, copy) void(^handler)(KADRemoteRegistrationResult *);
@end
@implementation KADRemoteNotificationPermissionOperation
-(instancetype)initWithApplication:(UIApplication *)application handler:(void (^)(KADRemoteRegistrationResult *))handler
{
    if (self = [super init]){
        _handler = handler;
        _application = application;
        /*
         This operation cannot run at the same time as any other remote notification
         permission operation.
         */
        [self addCondition:[KADMutualExclusive mutualExclusiveForClass:[KADRemoteNotificationPermissionOperation class]]];
    }
    return self;
}
-(void)execute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveResponse:) name:kRemoteNotificationName object:nil];
        [self.application registerForRemoteNotifications];
    });
}
-(void)didReceiveResponse:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSDictionary * userInfo = notification.userInfo;
    
    if ([userInfo[@"token"] isKindOfClass:[NSData class]]) {
        self.handler([KADRemoteRegistrationResult withToken:userInfo[@"token"]]);
    }
    else if ([userInfo[@"error"] isKindOfClass:[NSError class]]) {
        self.handler([KADRemoteRegistrationResult withError:userInfo[@"error"]]);
    }
    else {
        NSAssert(NO, @"Received a notification without a token and without an error.");
    }
    [self finish];
}
#pragma mark -
@end


@interface KADRemoteRegistrationResult ()
@property (nonatomic, strong) NSData * token;
@property (nonatomic, strong) NSError * error;
@end
@implementation KADRemoteRegistrationResult
+(instancetype)withError:(NSError *)error
{
    return [self withToken:nil error:error];
}
+(instancetype)withToken:(NSData *)token
{
    return [self withToken:token error:nil];
}
+(instancetype)withToken:(NSData *)token error:(NSError *)error
{
    KADRemoteRegistrationResult * result = [KADRemoteRegistrationResult new];
    result.token = token;
    result.error = error;
    return result;
}
@end