//
//  KADRemoteNotificationsCondition.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationCondition.h"
#import "KADOperation.h"

@interface KADRemoteNotificationsCondition : NSObject <KADOperationCondition>
@end


@interface KADRemoteRegistrationResult : NSObject
@property (nonatomic, readonly) NSData * token;
@property (nonatomic, readonly) NSError * error;
+(instancetype)withError:(NSError *)error;
+(instancetype)withToken:(NSData *)token;
@end


@class UIApplication;
@interface KADRemoteNotificationPermissionOperation : KADOperation
-(instancetype)initWithApplication:(UIApplication *)application handler:(void(^)(KADRemoteRegistrationResult *))handler;
@end
