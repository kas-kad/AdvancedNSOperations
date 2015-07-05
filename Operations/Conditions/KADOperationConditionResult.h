//
//  KADOperationConditionResult.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KADOperation;

extern NSString * kOperationConditionKey;

@interface KADOperationConditionResult : NSObject
@property (nonatomic, readonly) BOOL isSucceed;
@property (nonatomic, readonly) NSError * error;
+(KADOperationConditionResult *)satisfied;
+(KADOperationConditionResult *)failed:(NSError *)error;
+(void)evaluateConditions:(NSArray *)conditions operation:(KADOperation *)operation completion:(void(^)(NSArray * errors))completion;
@end
