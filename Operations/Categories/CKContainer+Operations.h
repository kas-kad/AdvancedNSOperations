//
//  CKContainer+Operations.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <CloudKit/CloudKit.h>

@interface CKContainer (Operations)
-(void)verifyPermission:(CKApplicationPermissions)permission
  requestingIfNecessary:(BOOL)shouldRequest
             completion:(void(^)(NSError *))completion;

@end
