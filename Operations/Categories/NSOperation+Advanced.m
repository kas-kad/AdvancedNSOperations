//
//  NSOperation+Advanced.m
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import "NSOperation+Advanced.h"

@implementation NSOperation (Advanced)
/**
 Add a completion block to be executed after the `NSOperation` enters the
 "finished" state.
 */
-(void)addCompletionBlock:(void(^)(void))block
{
    void(^existing)(void) = self.completionBlock;
    if (existing){
        /*
            If we already have a completion block, we construct a new one by
            chaining them together.
         */
        self.completionBlock = ^{
            existing();
            block();
        };
    } else {
        self.completionBlock = block;
    }
}

/// Add multiple depdendencies to the operation.
-(void)addDependencies:(NSArray /*NSOperation*/ *)dependencies
{
    for (NSOperation * dependency in dependencies) {
        [self addDependency:dependency];
    }
}
@end
