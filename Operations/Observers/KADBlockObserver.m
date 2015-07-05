//
//  KADBlockObserver.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADBlockObserver.h"

@interface KADBlockObserver ()

@property (nonatomic, copy) void(^startHandler)(KADOperation *);
@property (nonatomic, copy) void(^produceHandler)(KADOperation *, NSOperation *);
@property (nonatomic, copy) void(^finishHandler)(KADOperation *, NSArray *);

@end

@implementation KADBlockObserver
-(instancetype)initWithStartHandler:(void(^)(KADOperation *))startHandler
                    produceHandler:(void(^)(KADOperation *, NSOperation *))produceHandler
                    finishHandler:(void(^)(KADOperation *, NSArray *))finishHandler
{
    if (self = [super init]){
        self.startHandler = startHandler;
        self.produceHandler = produceHandler;
        self.finishHandler = finishHandler;
    }
    return self;
}

#pragma mark - OperationObserver protocol
-(void)operationDidStart:(KADOperation *)operation
{
    if (_startHandler){
        _startHandler(operation);
    }
}
-(void)operation:(KADOperation *)operation didProduceOperation:(NSOperation *)newOperation
{
    if (_produceHandler){
        _produceHandler(operation, newOperation);
    }
}
-(void)operationDidFinish:(KADOperation *)operation errors:(NSArray *)errors
{
    if (_finishHandler){
        _finishHandler(operation, errors);
    }
}
@end
