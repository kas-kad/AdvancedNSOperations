//
//  NSOperation+Advanced.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperation (Advanced)
-(void)addCompletionBlock:(void(^)(void))block;
-(void)addDependencies:(NSArray /*NSOperation*/ *)dependencies;
@end
