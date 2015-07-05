//
//  KADGroupOperation.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 05.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "KADOperation.h"

@interface KADGroupOperation : KADOperation

-(instancetype)initWithOperations:(NSArray /*NSOperations*/*)operations;
-(void)addOperation:(NSOperation *)operation;
-(void)aggregateError:(NSError *)error;
-(void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors;
@end
