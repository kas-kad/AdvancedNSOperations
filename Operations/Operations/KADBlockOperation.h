//
//  KADBlockOperation.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 05.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADOperation.h"

typedef void(^OperationCompletionBlock)(void);
typedef void(^OperationBlock)(OperationCompletionBlock completionBlock);

/// A sublcass of `Operation` to execute a block.
@interface KADBlockOperation : KADOperation

/**
 The designated initializer.
 
 - parameter block: The closure to run when the operation executes. This
 closure will be run on an arbitrary queue. The parameter passed to the
 block **MUST** be invoked by your code, or else the `BlockOperation`
 will never finish executing. If this parameter is `nil`, the operation
 will immediately finish.
 */
-(instancetype)initWithBlock:(OperationBlock)block;

/**
 A convenience initializer to execute a block on the main queue.
 
 - parameter mainQueueBlock: The block to execute on the main queue. Note
 that this block does not have a "continuation" block to execute (unlike
 the designated initializer). The operation will be automatically ended
 after the `mainQueueBlock` is executed.
 */
-(instancetype)initWithMainQueueBlock:(dispatch_block_t)block;
@end
