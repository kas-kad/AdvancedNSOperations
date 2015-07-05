//
//  KADCloudKitCondition.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADCloudKitCondition.h"
#import <CloudKit/CloudKit.h>
#import "KADMutualExclusive.h"
#import "CKContainer+Operations.h"
#import "KADOperationConditionResult.h"
#import "NSError+KADOperationErrors.h"

NSString * kContainerKey = @"CKContainer";

/// A condition describing that the operation requires access to a specific CloudKit container.
@interface KADCloudKitCondition ()
@property (nonatomic, strong) CKContainer * container;
@property (nonatomic, assign) CKApplicationPermissions permission;
@end

@implementation KADCloudKitCondition
/**
 - parameter container: the `CKContainer` to which you need access.
 - parameter permission: the `CKApplicationPermissions` you need for the
 container. This parameter has a default value of `[]`, which would get
 you anonymized read/write access.
 */
-(instancetype)initWithContainer:(CKContainer *)container permission:(CKApplicationPermissions)permission
{
    if (self = [super init]){
        _container = container;
        _permission = permission;
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
    /*
     CloudKit has no problem handling multiple operations at the same time
     so we will allow operations that use CloudKit to be concurrent with each
     other.
     */
    return NO;
}
-(void)evaluateForOperation:(KADOperation *)operation
                 completion:(void (^)(KADOperationConditionResult *))completion
{
    [self.container verifyPermission:self.permission requestingIfNecessary:NO completion:^(NSError * error)
    {
        if (error){
            NSError * conditionError = [NSError errorWithCode:KADConditionFailed userInfo:@{ kOperationConditionKey: self.name,
                            kContainerKey: self.container,
                            NSUnderlyingErrorKey: error }];
            
            completion([KADOperationConditionResult failed:conditionError]);
        } else {
            completion([KADOperationConditionResult satisfied]);
        }
    }];
}
-(NSOperation *)dependencyForOperation:(KADOperation *)operation
{
    return [[KADCloudKitPermissionOperation alloc]initWithContainer:self.container permission:self.permission];
}
@end


/**
 This operation asks the user for permission to use CloudKit, if necessary.
 If permission has already been granted, this operation will quickly finish.
 */
@interface KADCloudKitPermissionOperation ()
@property (nonatomic, strong) CKContainer * container;
@property (nonatomic, assign) CKApplicationPermissions permission;
@end
@implementation KADCloudKitPermissionOperation
-(instancetype)initWithContainer:(CKContainer *)container
                      permission:(CKApplicationPermissions)permission
{
    if (self = [super init]){
        _container = container;
        _permission = permission;
        if (_permission != 0){
            /*
             Requesting non-zero permissions means that this potentially presents
             an alert, so it should not run at the same time as anything else
             that presents an alert.
             */
            [self addCondition: [KADMutualExclusive alertMutex]];
        }
    }
    return self;
}
-(void)execute
{
    [self.container verifyPermission:self.permission
               requestingIfNecessary:YES
                          completion:^(NSError * error)
    {
        [self finishWithError:error];
    }];
}
@end



