//
//  NSError+KADOperationErrors.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KADOperationErrorCode) {
KADConditionFailed = 1,
KADExecutionFailed = 2
};


@interface NSError (KADOperationErrors)
+(instancetype)errorWithCode:(NSUInteger)code;
+(instancetype)errorWithCode:(NSUInteger)code userInfo:(NSDictionary *)info;
@end
