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

@interface KADOperation ()
@property (nonatomic, assign) BOOL hasFinishedAlready;
@property (nonatomic, assign) KADOperationState state;
@end

@implementation KADOperation

// use the KVO mechanism to indicate that changes to "state" affect other properties as well
+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([@[@"isReady", @"isExecuting", @"isFinished",@"isCancelled"] containsObject:key])
    {
        return [NSSet setWithArray:@[@"state"]];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

/**
 Indicates that the Operation can now begin to evaluate readiness conditions,
 if appropriate.
 */
-(void)willEnqueue
{
    self.state = KADPending;
}
-(void)setState:(KADOperationState)newState
{
    // Manually fire the KVO notifications for state change, since this is "private".
    [self willChangeValueForKey:@"state"];
    
    // cannot leave the cancelled state
    // cannot leave the finished state
    if (_state != KADCancelled && _state != KADFinished){
        NSAssert(_state != newState, @"Performing invalid cyclic state transition.");
        _state = newState;
    }
    
    [self didChangeValueForKey:@"state"];
}
-(BOOL)isReady
{
    switch (self.state) {
        case KADPending:
            if ([super isReady]) {
                [self evaluateConditions];
            }
            return false;
            break;
        case KADReady:
            return [super isReady];
            break;
        default:
            return NO;
            break;
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
-(BOOL)isCancelled
{
    return self.state == KADCancelled;
}
-(void)evaluateConditions
{
    NSAssert(self.state == KADPending, @"evaluateConditions() was called out-of-order");
    
    self.state = KADEvaluatingConditions;
    
    [KADOperationConditionResult evaluateConditions:self.conditions operation:self completion:^(NSArray * failures) {
        
        if (failures.count == 0) {
            // If there were no errors, we may proceed.
            self.state = KADReady;
        }
        else {
            self.state = KADCancelled;
            [self finish:failures];
        }
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
-(void)addCondition:(NSObject <KADOperationCondition> __nonnull*)condition
{
    NSAssert(self.state < KADEvaluatingConditions, @"Cannot modify conditions after execution has begun.");
    [self.conditions addObject:condition];
}
-(void)addDependency:(NSOperation __nonnull*)op
{
    NSAssert(self.state <= KADExecuting, @"Dependencies cannot be modified after execution has begun.");
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
-(void)addObserver:(NSObject <KADOperationObserver> __nonnull*)observer
{
    NSAssert(self.state < KADExecuting, @"Cannot modify observers after execution has begun.");
    [self.observers addObject:observer];
}

#pragma mark - Execution and Cancellation
-(void)start
{
    NSAssert(self.state == KADReady, @"This operation must be performed on an operation queue.");
    self.state = KADExecuting;
    
    for (NSObject <KADOperationObserver> *observer in self.observers) {
        [observer operationDidStart:self];
    }
    
    [self execute];
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
    [self finish:nil];
}
-(void)cancel
{
    [self cancelWithError:nil];
}
-(void)cancelWithError:(NSError __nullable*)error
{

    [self.internalErrors addObject:error];
    self.state = KADCancelled;
}
-(void)produceOperation:(NSOperation __nonnull*)operation
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
-(void)finishWithError:(NSError __nullable*)error
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
-(void)finish:(NSArray __nullable*)errors
{
    if (!_hasFinishedAlready)
    {
        _hasFinishedAlready = YES;
        self.state = KADFinishing;
        
        NSArray * combinedErrors = [_internalErrors arrayByAddingObjectsFromArray:errors];
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
-(void)finished:(NSArray __nullable*)errors
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
