//
//  SCItemBehaviorManager.h
//  Carousel
//
//  Created by R_style Man on 15-1-21.
//  Copyright (c) 2015年 R_style Man. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SCItemBehaviorManager : NSObject

@property (readonly,strong) UIGravityBehavior* gravityBehavior;
@property (readonly,strong) UICollisionBehavior* collisionBehavior;
@property (readonly,strong) NSMutableDictionary* attachmentBehaviors;
@property (readonly,strong) UIDynamicAnimator* animator;

-(instancetype) initWithAnimator:(UIDynamicAnimator*) animator;

-(void) addItem:(UICollectionViewLayoutAttributes*) item anchor:(CGPoint) anchor;
-(void) removeItemAtIndexPath:(NSIndexPath*) indexPath;
-(void) updateItemCollection:(NSArray*) items;
-(NSArray*) currentlyManagedItemPaths;

@end
