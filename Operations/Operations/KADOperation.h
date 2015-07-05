//
//  KADOperation.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationObserver.h"
#import "KADOperationCondition.h"

typedef NS_ENUM(NSUInteger, KADOperationState) {
    /// The initial state of an `Operation`.
    KADInitialized,
    
    /// The `Operation` is ready to begin evaluating conditions.
    KADPending,
    
    /// The `Operation` is evaluating conditions.
    KADEvaluatingConditions,
    
    /**
     The `Operation`'s conditions have all been satisfied, and it is ready
     to execute.
     */
    KADReady,
    
    /// The `Operation` is executing.
    KADExecuting,
    
    /**
     Execution of the `Operation` has finished, but it has not yet notified
     the queue of this.
     */
    KADFinishing,
    
    /// The `Operation` has finished executing.
    KADFinished,
    
    /// The `Operation` has been cancelled.
    KADCancelled
};

@interface KADOperation : NSOperation
@property (nonatomic, assign) BOOL userInitiated;
@property (nonatomic, readonly) KADOperationState state;
@property (nonatomic, strong) NSMutableArray * conditions, * observers, * internalErrors;;

-(void)addObserver:(NSObject <KADOperationObserver> *)observer;
-(void)addCondition:(NSObject <KADOperationCondition>*)condition;
-(void)willEnqueue;
-(void)finish;
-(void)finish:(NSArray *)errors;
-(void)finishWithError:(NSError *)error;
-(void)finished:(NSArray *)errors;
-(void)execute;
-(void)produceOperation:(NSOperation *)operation;
@end
