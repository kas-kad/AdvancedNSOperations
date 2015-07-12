//
//  KADOperationQueue.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADOperationQueue.h"
#import "KADOperation.h"
#import "KADBlockObserver.h"
#import "KADOperationCondition.h"
#import "KADExclusivityController.h"
#import "NSOperation+Advanced.h"

@implementation KADOperationQueue
-(void)addOperation:(NSOperation *)operation
{
    if ([operation isKindOfClass:[KADOperation class]]){
        KADOperation * op = (KADOperation *)operation;
        __weak typeof(self) weakSelf = self;
        // Set up a `BlockObserver` to invoke the `OperationQueueDelegate` method.
        KADBlockObserver * delegate = [[KADBlockObserver alloc]
                                       initWithStartHandler:nil
                                             produceHandler:^(KADOperation * oper, NSOperation * newOp) {
                                                [weakSelf addOperation:newOp]; }
                                              finishHandler:^(KADOperation * oper, NSArray * errors) {
                                                [weakSelf.delegate operationQueue:weakSelf operationDidFinish:oper withErrors:errors]; }];
        
        [op addObserver:delegate];
        
        // Extract any dependencies needed by this operation.
        NSMutableArray * dependencies = [NSMutableArray arrayWithCapacity:op.conditions.count];
        [op.conditions enumerateObjectsUsingBlock:^(NSObject <KADOperationCondition> * condition, NSUInteger idx, BOOL *stop)
        {
            NSOperation * dependency = [condition dependencyForOperation:op];
            if (dependency){
                [dependencies addObject:dependency];
            }
        }];
        
        [dependencies enumerateObjectsUsingBlock:^(NSOperation * dependency, NSUInteger idx, BOOL *stop)
        {
            [op addDependency:dependency];
            [self addOperation:dependency];
        }];
        
        /*
         With condition dependencies added, we can now see if this needs
         dependencies to enforce mutual exclusivity.
         */
         
         NSMutableArray * concurrencyCategories = [NSMutableArray array];
         
         [op.conditions enumerateObjectsUsingBlock:^(NSObject <KADOperationCondition> *condition, NSUInteger idx, BOOL *stop){
             if (![condition isMutuallyExclusive]){
                 return;
             }
             [concurrencyCategories addObject:condition.name];
         }];
        
        if (concurrencyCategories.count) {
            // Set up the mutual exclusivity dependencies.
            KADExclusivityController * exclusivityController = [KADExclusivityController sharedExclusivityController];
            
            [exclusivityController addOperation:op categories:concurrencyCategories];
            
            KADBlockObserver * obs = [[KADBlockObserver alloc]
                    initWithStartHandler:nil
                        produceHandler:nil
                         finishHandler:^(KADOperation * oper, NSArray * error) {
                             [exclusivityController removeOperation:oper categories:concurrencyCategories];
                         }];
            
            [op addObserver:obs];
        }
        
        /*
         Indicate to the operation that we've finished our extra work on it
         and it's now it a state where it can proceed with evaluating conditions,
         if appropriate.
         */
        [op willEnqueue];
        
    } else {
        /*
         For regular `NSOperation`s, we'll manually call out to the queue's
         delegate we don't want to just capture "operation" because that
         would lead to the operation strongly referencing itself and that's
         the pure definition of a memory leak.
         */
        __weak typeof(self) weakSelf = self;
        __weak NSOperation * weakOperation = operation;
        [operation addCompletionBlock:^{
            KADOperationQueue * queue = weakSelf;
            NSOperation * op = weakOperation;
            if (queue && op){
                if ([queue.delegate respondsToSelector:@selector(operationQueue:operationDidFinish:withErrors:)]){
                    [queue.delegate operationQueue:queue operationDidFinish:op withErrors:nil];
                }
            }
        }];
    }
    if ([self.delegate respondsToSelector:@selector(operationQueue:willAddOperation:)]){
        [self.delegate operationQueue:self willAddOperation:operation];
    }
    [super addOperation:operation];
}
-(void)addOperations:(NSArray *)ops waitUntilFinished:(BOOL)wait
{
    /*
     The base implementation of this method does not call `addOperation()`,
     so we'll call it ourselves.
     */
    for (NSOperation * op in ops){
        [self addOperation:op];
    }
    if (wait){
        for (NSOperation * op in ops){
            [op waitUntilFinished];
        }
    }
    
}
@end
