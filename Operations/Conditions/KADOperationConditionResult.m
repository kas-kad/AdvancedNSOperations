//
//  KADOperationConditionResult.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADOperationConditionResult.h"
#import "KADOperation.h"
#import "KADOperationCondition.h"
#import "NSError+KADOperationErrors.h"

NSString * kOperationConditionKey = @"OperationCondition";

@interface KADOperationConditionResult ()
@property (nonatomic, assign) BOOL isSucceed;
@property (nonatomic, strong) NSError * error;
@end

@implementation KADOperationConditionResult
+(KADOperationConditionResult *)satisfied
{
    return [self isSucceed:YES error:nil];
}
+(KADOperationConditionResult *)failed:(NSError *)error
{
    return [self isSucceed:NO error:error];
}
+(KADOperationConditionResult *)isSucceed:(BOOL)isSucceed error:(NSError *)error
{
    KADOperationConditionResult * newResult = [KADOperationConditionResult new];
    newResult.isSucceed = isSucceed;
    newResult.error = error;
    return newResult;
}
-(NSError *)error
{
    if (!_isSucceed){
        return _error;
    } else {
        return nil;
    }
}
+(void)evaluateConditions:(NSArray *)conditions operation:(KADOperation *)operation completion:(void(^)(NSArray * errors))completion
{
    // Check conditions.
    dispatch_group_t conditionGroup = dispatch_group_create();
    
    //array of OperationConditionResult
    NSMutableArray * results = [NSMutableArray arrayWithCapacity:conditions.count];
    
    // Ask each condition to evaluate and store its result in the "results" array.
    [conditions enumerateObjectsUsingBlock:^(NSObject <KADOperationCondition> * condition, NSUInteger idx, BOOL *stop) {

        dispatch_group_enter(conditionGroup);
        [condition evaluateForOperation:operation completion:^(KADOperationConditionResult * result) {
            
            results[idx] = result;
            dispatch_group_leave(conditionGroup);
        }];
    }];
    
    // After all the conditions have evaluated, this block will execute.
    dispatch_group_notify(conditionGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        // Aggregate the errors that occurred, in order.
        NSArray * failures = [results valueForKeyPath:@"error"];
        
        /*
         If any of the conditions caused this operation to be cancelled,
         check for that.
         */
        if (operation.isCancelled) {
            failures = [failures arrayByAddingObject: [NSError errorWithCode:KADConditionFailed]];
        }
        if (completion){
            completion(failures);
        }
    });
}

@end
