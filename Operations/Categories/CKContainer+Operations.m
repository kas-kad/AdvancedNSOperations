//
//  CKContainer+Operations.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "CKContainer+Operations.h"

@implementation CKContainer (Operations)
/**
 Verify that the current user has certain permissions for the `CKContainer`,
 and potentially requesting the permission if necessary.
 
 - parameter permission: The permissions to be verified on the container.
 
 - parameter shouldRequest: If this value is `true` and the user does not
 have the passed `permission`, then the user will be prompted for it.
 
 - parameter completion: A closure that will be executed after verification
 completes. The `NSError` passed in to the closure is the result of either
 retrieving the account status, or requesting permission, if either
 operation fails. If the verification was successful, this value will
 be `nil`.
 */
-(void)verifyPermission:(CKApplicationPermissions)permission
  requestingIfNecessary:(BOOL)shouldRequest
             completion:(void(^)(NSError *))completion
{
    [self verifyAccountStatus:self permission:permission shouldRequest:shouldRequest completion:completion];
}

#pragma mark - Helpers
-(void)verifyAccountStatus:(CKContainer *)container
                permission:(CKApplicationPermissions)permission
             shouldRequest:(BOOL)shouldRequest
                completion:(void(^)(NSError *))completion
{
    [container accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error)
     {
         if (accountStatus == CKAccountStatusAvailable){
             if (permission != 0){
                 [self verifyPermission:container
                             permission:permission
                          shouldRequest:shouldRequest
                             completion:completion];
             } else {
                 completion(nil);
             }
         } else {
             completion(error);
         }
     }];
}

-(void)verifyPermission:(CKContainer *)container
             permission:(CKApplicationPermissions)permission
          shouldRequest:(BOOL)shouldRequest
             completion:(void(^)(NSError *))completion
{
    [container statusForApplicationPermission:permission completionHandler:^(CKApplicationPermissionStatus permissionStatus, NSError *error) {
        if (permissionStatus == CKApplicationPermissionStatusGranted){
            completion(nil);
        } else if (permissionStatus == CKApplicationPermissionStatusInitialState && shouldRequest) {
            [self requestPermission:container
                         permission:permission
                         completion:completion];
        } else {
            completion(error);
        }
    }];
}

-(void)requestPermission:(CKContainer *)container
              permission:(CKApplicationPermissions)permission
              completion:(void(^)(NSError *))completion
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [container requestApplicationPermission:permission completionHandler:^(CKApplicationPermissionStatus requestStatus, NSError *error) {
            if (requestStatus == CKApplicationPermissionStatusGranted){
                completion(nil);
            } else {
                completion(error);
            }
        }];
    });
}

@end