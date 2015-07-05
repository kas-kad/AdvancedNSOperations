//
//  NSError+KADOperationErrors.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "NSError+KADOperationErrors.h"


@implementation NSError (KADOperationErrors)
+(instancetype)errorWithCode:(NSUInteger)code
{
    return [self errorWithCode:code userInfo:nil];
}
+(instancetype)errorWithCode:(NSUInteger)code userInfo:(NSDictionary *)info
{
    return [NSError errorWithDomain:@"OperationErrors" code:code userInfo:info];
}

@end
