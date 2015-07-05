//
//  KADOperationObserver.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KADOperation;

/**
 The protocol that types may implement if they wish to be notified of significant
 operation lifecycle events.
 */
@protocol KADOperationObserver <NSObject>

/// Invoked immediately prior to the `Operation`'s `execute()` method.
-(void)operationDidStart:(KADOperation *)operation;

/// Invoked when `Operation.produceOperation(_:)` is executed.
-(void)operation:(KADOperation *)operation didProduceOperation:(NSOperation *)newOperation;

/**
 Invoked as an `Operation` finishes, along with any errors produced during
 execution (or readiness evaluation).
 */
-(void)operationDidFinish:(KADOperation *)operation errors:(NSArray *)errors;

@end
