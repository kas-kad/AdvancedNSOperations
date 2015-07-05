//
//  KADReachabilityCondition.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 05.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationCondition.h"

/**
 This is a condition that performs a very high-level reachability check.
 It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
 Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
 */
@interface KADReachabilityCondition : NSObject <KADOperationCondition>

@end
