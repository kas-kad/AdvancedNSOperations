//
//  KADOperation.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADOperation.h"
#import "KADOperationObserver.h"
#import "KADOperationCondition.h"

@interface KADOperation () {
    KADOperationState _state;
}
@property (nonatomic, strong) NSMutableArray * kad_internalErrors;
@property (nonatomic, assign) BOOL hasFinishedAlready;
@end

@implementation KADOperation

#pragma mark - LAZY VARS
-(NSMutableArray *)kad_internalErrors
{
    if (!_kad_internalErrors) {
        _kad_internalErrors = [NSMutableArray array];
    }
    return _kad_internalErrors;
}

#pragma mark - KVO
// use the KVO mechanism to indicate that changes to "state" affect other properties as well
+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([@[@"isReady", @"isExecuting", @"isFinished"] containsObject:key])
    {
        return [NSSet setWithArray:@[@"state"]];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

/**
 Indicates that the Operation can now begin to evaluate readiness conditions,
 if appropriate.
 */
-(BOOL)canTransitionToState:(KADOperationState)target
{
    return (self.state == KADInitialized && target == KADPending)
        || (self.state == KADPending && target == KADEvaluatingConditions)
        || (self.state == KADEvaluatingConditions && target == KADReady)
        || (self.state == KADReady && target == KADExecuting)
        || (self.state == KADReady && target == KADFinishing)
        || (self.state == KADExecuting && target == KADFinishing)
        || (self.state == KADFinishing && target == KADFinished);
}

-(void)willEnqueue
{
    self.state = KADPending;
}
-(KADOperationState)state
{
    @synchronized(self) {
        return _state;
    }
}
-(void)setState:(KADOperationState)newState
{
    // Manually fire the KVO notifications for state change, since this is "private".
    [self willChangeValueForKey:@"state"];
    
    @synchronized(self) {
        if (_state == KADFinished) {
            return;
        }
        NSAssert([self canTransitionToState:newState], @"Performing invalid state transition.");
        _state = newState;
    }
    
    [self didChangeValueForKey:@"state"];
}
-(BOOL)isReady
{
    switch (self.state) {
        case KADInitialized:
            // If the operation has been cancelled, "isReady" should return true
            return self.cancelled;
        case KADPending:
            // If the operation has been cancelled, "isReady" should return true
            if (self.cancelled) {
                return YES;
            } else {
                // If super isReady, conditions can be evaluated
                if (super.ready) {
                    [self evaluateConditions];
                }
                // Until conditions have been evaluated, "isReady" returns false
                return NO;
            }
        case KADReady:
            return super.ready || self.cancelled;
        default:
            return NO;
    }
}
-(BOOL)userInitiated
{
    return self.qualityOfService == NSQualityOfServiceUserInitiated;
}
-(void)setUserInitiated:(BOOL)newValue
{
    NSAssert(self.state < KADExecuting, @"Cannot modify userInitiated after execution has begun.");
    self.qualityOfService = newValue ? NSQualityOfServiceUserInitiated : NSQualityOfServiceDefault;
}
-(BOOL)isExecuting
{
    return self.state == KADExecuting;
}
-(BOOL)isFinished
{
    return self.state == KADFinished;
}
-(void)evaluateConditions
{
    NSAssert(self.state == KADPending && !self.cancelled, @"evaluateConditions() was called out-of-order");
    
    self.state = KADEvaluatingConditions;
    
    [KADOperationConditionResult evaluateConditions:self.conditions operation:self completion:^(NSArray * failures) {
        [self.kad_internalErrors addObjectsFromArray:failures];
        self.state = KADReady;
    }];
}

#pragma mark - CONDITIONS
-(NSMutableArray *)conditions
{
    if (!_conditions){
        _conditions = [NSMutableArray array];
    }
    return _conditions;
}
-(void)addCondition:(NSObject <KADOperationCondition>*)condition
{
    NSAssert(self.state < KADEvaluatingConditions, @"Cannot modify observers after execution has begun.");
    [self.conditions addObject:condition];
}
-(void)addDependency:(NSOperation *)op
{
    NSAssert(self.state < KADExecuting, @"Dependencies cannot be modified after execution has begun.");
    [super addDependency:op];
}

#pragma mark - OBSERVERS
-(NSMutableArray *)observers
{
    if (!_observers){
        _observers = [NSMutableArray array];
    }
    return _observers;
}
-(void)addObserver:(NSObject <KADOperationObserver> *)observer
{
    NSAssert(self.state < KADExecuting, @"Cannot modify observers after execution has begun.");
    [self.observers addObject:observer];
}

#pragma mark - Execution and Cancellation
-(void)start
{
    // NSOperation.start() contains important logic that shouldn't be bypassed.
    [super start];
    
    // If the operation has been cancelled, we still need to enter the "Finished" state.
    if (self.cancelled) {
        [self finish];
    }
}
-(void)main
{
    NSAssert(self.state == KADReady, @"This operation must be performed on an operation queue.");
    if (self.kad_internalErrors.count == 0 && !self.cancelled) {
        self.state = KADExecuting;
        for (NSObject <KADOperationObserver>* observer in self.observers) {
            [observer operationDidStart:self];
        }
        [self execute];
    } else {
        [self finish];
    }
}
/**
 `execute()` is the entry point of execution for all `Operation` subclasses.
 If you subclass `Operation` and wish to customize its execution, you would
 do so by overriding the `execute()` method.
 
 At some point, your `Operation` subclass must call one of the "finish"
 methods defined below; this is how you indicate that your operation has
 finished its execution, and that operations dependent on yours can re-evaluate
 their readiness state.
 */
-(void)execute
{
    NSLog(@"%@ must override `execute()`.", NSStringFromClass(self.class));
    [self finish];
}
-(void)cancel
{
    if (self.finished) {
        return;
    }
    [super cancel];
    if (self.state > KADReady) {
        [self finish];
    }
}
-(void)cancelWithError:(NSError *)error
{
    if (error) {
        [self.kad_internalErrors addObject:error];
    }
    [self cancel];
}
-(void)produceOperation:(NSOperation *)operation
{
    for (NSObject <KADOperationObserver> *observer in self.observers) {
        [observer operation:self didProduceOperation:operation];
    }
}

#pragma mark - FINISHING
/**
 Most operations may finish with a single error, if they have one at all.
 This is a convenience method to simplify calling the actual `finish()`
 method. This is also useful if you wish to finish with an error provided
 by the system frameworks. As an example, see `DownloadEarthquakesOperation`
 for how an error from an `NSURLSession` is passed along via the
 `finishWithError()` method.
 */
-(void)finish
{
    [self finish:nil];
}
-(void)finishWithError:(NSError *)error
{
    if (error){
        [self finish:@[error]];
    } else {
        [self finish:nil];
    }
}

/**
 A private property to ensure we only notify the observers once that the
 operation has finished.
 */
-(void)finish:(NSArray *)errors
{
    if (!self.hasFinishedAlready)
    {
        self.hasFinishedAlready = YES;
        self.state = KADFinishing;
        
        NSArray * combinedErrors = self.kad_internalErrors.copy;
        if (errors) {
            combinedErrors = [combinedErrors arrayByAddingObjectsFromArray:errors];
        }
        [self finished:combinedErrors];
        
        for (NSObject <KADOperationObserver>* observer in self.observers) {
            [observer operationDidFinish:self errors:combinedErrors];
        }
        
        self.state = KADFinished;
    }
}

/**
 Subclasses may override `finished(_:)` if they wish to react to the operation
 finishing with errors. For example, the `LoadModelOperation` implements
 this method to potentially inform the user about an error when trying to
 bring up the Core Data stack.
 */
-(void)finished:(NSArray *)errors
{
    // No op.
}

-(void)waitUntilFinished
{
    /*
     Waiting on operations is almost NEVER the right thing to do. It is
     usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
     or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
     use waiting when they should instead be chaining discrete operations
     together using dependencies.
     
     To reinforce this idea, invoking `waitUntilFinished()` will crash your
     app, as incentive for you to find a more appropriate way to express
     the behavior you're wishing to create.
     */
    NSAssert(NO, @"Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.");
}
@end
