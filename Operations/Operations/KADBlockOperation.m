//
//  KADBlockOperation.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 05.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADBlockOperation.h"

@interface KADBlockOperation ()
@property (nonatomic, copy) OperationBlock block;
@end

@implementation KADBlockOperation

/**
 The designated initializer.
 
 - parameter block: The closure to run when the operation executes. This
 closure will be run on an arbitrary queue. The parameter passed to the
 block **MUST** be invoked by your code, or else the `BlockOperation`
 will never finish executing. If this parameter is `nil`, the operation
 will immediately finish.
 */
-(instancetype)initWithBlock:(OperationBlock)block
{
    if (self = [super init]){
        _block = block;
    }
    return self;
}

-(instancetype)initWithMainQueueBlock:(dispatch_block_t)block
{
    self = [self initWithBlock:^(void(^operationCompletionBlock)(void)) {
        block();
        if (operationCompletionBlock){
            operationCompletionBlock();
        }
    }];
    return self;
}

-(void)execute
{
    OperationCompletionBlock completion = ^{
        [self finish];
    };
    
    if (self.block){
        self.block(completion);
    } else {
        completion();
        return;
    }
    
}
@end
