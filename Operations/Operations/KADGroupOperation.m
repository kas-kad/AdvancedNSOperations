//
//  KADGroupOperation.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 05.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADGroupOperation.h"
#import "KADOperationQueue.h"

/**
 A subclass of `Operation` that executes zero or more operations as part of its
 own execution. This class of operation is very useful for abstracting several
 smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
 is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.
 
 Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
 but part of the chain may "loop". For example, if you have an operation that
 requires the user to be authenticated, you may consider putting the "login"
 operation inside a group operation. That way, the "login" operation may produce
 subsequent operations (still within the outer `GroupOperation`) that will all
 be executed before the rest of the operations in the initial chain of operations.
 */

@interface KADGroupOperation () <KADOperationQueueDelegate>
@property (nonatomic, strong) KADOperationQueue * internalQueue;
@property (nonatomic, copy) NSBlockOperation * finishingOperation;
@property (nonatomic, strong) NSMutableArray /*NSError*/* aggregatedErrors;
@end

@implementation KADGroupOperation
-(instancetype)initWithOperations:(NSArray /*NSOperations*/*)operations
{
    if (self = [super init]){
        _internalQueue = [KADOperationQueue new];
        _internalQueue.suspended = YES;
        _internalQueue.delegate = self;
        
        for (NSOperation * op in operations){
            [_internalQueue addOperation:op];
        }
    }
    return self;
}

-(void)cancel
{
    [self.internalQueue cancelAllOperations];
    [super cancel];
}
-(void)execute
{
    self.internalQueue.suspended = NO;
    [self.internalQueue addOperation:self.finishingOperation];
}
-(void)addOperation:(NSOperation *)operation
{
    [self.internalQueue addOperation:operation];
}

/**
 Note that some part of execution has produced an error.
 Errors aggregated through this method will be included in the final array
 of errors reported to observers and to the `finished(_:)` method.
 */
-(void)aggregateError:(NSError *)error
{
    [self.aggregatedErrors addObject:error];
}

-(void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors
{
    // For use by subclassers.
}

#pragma mark - KADOperationQueueDelegate
-(void)operationQueue:(KADOperationQueue *)operationQueue willAddOperation:(NSOperation *)operation
{
    NSAssert(!self.finishingOperation.finished && !self.finishingOperation.executing, @"cannot add new operations to a group after the group has completed");

    /*
     Some operation in this group has produced a new operation to execute.
     We want to allow that operation to execute before the group completes,
     so we'll make the finishing operation dependent on this newly-produced operation.
     */
    if (operation != self.finishingOperation) {
        [self.finishingOperation addDependency:operation];
    }

}
-(void)operationQueue:(KADOperationQueue *)operationQueue operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors
{
    [self.aggregatedErrors addObjectsFromArray:errors];
    
    if (operation == self.finishingOperation){
        self.internalQueue.suspended = YES;
        [self finishWithError:self.aggregatedErrors.copy];
    } else {
        [self operationDidFinish:operation withErrors:errors];
    }
}
@end
