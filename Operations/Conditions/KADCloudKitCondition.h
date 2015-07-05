//
//  KADCloudKitCondition.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationCondition.h"
#import "KADOperation.h"
#import <CloudKit/CKContainer.h>

extern NSString * kContainerKey;

/// A condition describing that the operation requires access to a specific CloudKit container.
@interface KADCloudKitCondition : NSObject <KADOperationCondition>
-(instancetype)initWithContainer:(CKContainer *)container permission:(CKApplicationPermissions)permission;
@end

/**
 This operation asks the user for permission to use CloudKit, if necessary.
 If permission has already been granted, this operation will quickly finish.
 */
@interface KADCloudKitPermissionOperation : KADOperation
-(instancetype)initWithContainer:(CKContainer *)container permission:(CKApplicationPermissions)permission;
@end