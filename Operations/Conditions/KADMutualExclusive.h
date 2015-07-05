//
//  KADMutualExclusive.h
//  AdvancedNSOperation
//
//  Created by Andrey K. on 04.07.15.
//  Copyright (c) 2015 Andrey K. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KADOperationCondition.h"

@interface KADMutualExclusive : NSObject <KADOperationCondition>
+(instancetype)mutualExclusiveForClass:(Class)class;

+(instancetype)alertMutex;
+(instancetype)viewControllerMutex;
@end
