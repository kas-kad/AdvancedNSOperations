//
//  KADExclusivityController.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 01.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KADOperation;

/**
 `ExclusivityController` is a singleton to keep track of all the in-flight
 `Operation` instances that have declared themselves as requiring mutual exclusivity.
 We use a singleton because mutual exclusivity must be enforced across the entire
 app, regardless of the `OperationQueue` on which an `Operation` was executed.
 */

@interface KADExclusivityController : NSObject
+(instancetype)sharedExclusivityController;

-(void)addOperation:(KADOperation *)operation categories:(NSArray */*[String]*/)categories;
-(void)removeOperation:(KADOperation *)operation categories:(NSArray */*[String]*/)categories;
@end
