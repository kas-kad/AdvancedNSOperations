//
//  KADOperationQueue.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KADOperation, KADOperationQueue;

/**
 The delegate of an `OperationQueue` can respond to `Operation` lifecycle
 events by implementing these methods.
 
 In general, implementing `OperationQueueDelegate` is not necessary; you would
 want to use an `OperationObserver` instead. However, there are a couple of
 situations where using `OperationQueueDelegate` can lead to simpler code.
 For example, `GroupOperation` is the delegate of its own internal
 `OperationQueue` and uses it to manage dependencies.
 */
@protocol KADOperationQueueDelegate <NSObject>
@optional
-(void)operationQueue:(KADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation;
-(void)operationQueue:(KADOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;
@end


/**
 `OperationQueue` is an `NSOperationQueue` subclass that implements a large
 number of "extra features" related to the `Operation` class:
 
 - Notifying a delegate of all operation completion
 - Extracting generated dependencies from operation conditions
 - Setting up dependencies to enforce mutual exclusivity
 */
@interface KADOperationQueue : NSOperationQueue
@property (nonatomic, weak) id <KADOperationQueueDelegate> delegate;
@end
