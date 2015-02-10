//
//  SCItemBehaviorManager.m
//  Carousel
//
//  Created by R_style Man on 15-1-21.
//  Copyright (c) 2015年 R_style Man. All rights reserved.
//

#import "SCItemBehaviorManager.h"

@implementation SCItemBehaviorManager

-(instancetype) initWithAnimator:(UIDynamicAnimator *)animator
{
    self = [super init];
    if (self) {
        _animator = animator;
        _attachmentBehaviors = [NSMutableDictionary dictionary];
        
        [self createGravityBehavior];
        [self createCollisionBehavior];
        
        [self.animator addBehavior:self.gravityBehavior];
        [self.animator addBehavior:self.collisionBehavior];
    }
    return self;
}

-(void) createGravityBehavior
{
    _gravityBehavior = [[UIGravityBehavior alloc] init];
    _gravityBehavior.magnitude = 0.3;
}

-(void) createCollisionBehavior
{
    _collisionBehavior = [[UICollisionBehavior alloc] init];
    _collisionBehavior.collisionMode = UICollisionBehaviorModeBoundaries;
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    //Need to add item behavior specific to this
    UIDynamicItemBehavior* itemBehavior = [[UIDynamicItemBehavior alloc] init];
    itemBehavior.elasticity = 1;
    //Add it as a child behavior
    [_collisionBehavior addChildBehavior:itemBehavior];
}

-(UIAttachmentBehavior*) createAttachmentBehaviorForItem:(id<UIDynamicItem>) item anchor:(CGPoint) anchor
{
    UIAttachmentBehavior* attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:anchor];
    attachmentBehavior.damping = 0.5;
    attachmentBehavior.frequency = 0.8;
    attachmentBehavior.length = 0;
    
    return attachmentBehavior;
}

-(void)addItem:(UICollectionViewLayoutAttributes *)item anchor:(CGPoint)anchor
{
    UIAttachmentBehavior* attachmentBehavior = [self createAttachmentBehaviorForItem:item anchor:anchor];
    // Add the behavior to the animator
    [self.animator addBehavior:attachmentBehavior];
    //And store it in the dictionary. keyd by the indexPath
    [_attachmentBehaviors setObject:attachmentBehavior forKey:item.indexPath];
    
    //Also need to add this item to the global behaviors
    [self.gravityBehavior addItem:item];
    [self.collisionBehavior addItem:item];
}

-(void) removeItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove the attachment behavior from the animator
    UIAttachmentBehavior* attachmentBehavior = self.attachmentBehaviors[indexPath];
    [self.animator removeBehavior:attachmentBehavior];
    
    // Remove the item from the global behaviors
    for (UICollectionViewLayoutAttributes* attr in [self.gravityBehavior.items copy])
    {
        if ([attr.indexPath isEqual:indexPath])
        {
            [self.gravityBehavior removeItem:attr];
        }
    }
    for (UICollectionViewLayoutAttributes* attr in [self.collisionBehavior.items copy])
    {
        if ([attr.indexPath isEqual:indexPath])
        {
            [self.collisionBehavior removeItem:attr];
        }
    }
    
    // And remove the entry form our dictionary
    [_attachmentBehaviors removeObjectForKey:indexPath];
}

-(void) updateItemCollection:(NSArray *)items
{
    // Let's find the ones we need to remove. We work in indePaths here
    NSMutableSet* toRemove = [NSMutableSet setWithArray:[self.attachmentBehaviors allKeys]];
    
    [toRemove minusSet:[NSSet setWithArray:[items valueForKey:@"indexPath"]]];
    
    // Let's remove any we no longer need
    for (NSIndexPath* indexPath in toRemove)
    {
        [self removeItemAtIndexPath:indexPath];
    }
    
    // Find the items we need to add springs to, A bit more complicated = (
    // Loop through the items we want
    NSArray* existingIndexPaths = [self currentlyManagedItemPaths];
    for (UICollectionViewLayoutAttributes* attr in items)
    {
        // Find whether this item matches an existing index path
        BOOL alreadyExists = NO;
        for (NSIndexPath* indexPath in existingIndexPaths)
        {
            if ([indexPath isEqual:attr.indexPath])
            {
                alreadyExists = YES;
            }
        }
        // If it dosen't then let's add it
        if (!alreadyExists)
        {
            // Need to add
            [self addItem:attr anchor:attr.center];
        }
    }
}

-(NSArray*)currentlyManagedItemPaths
{
    return [self.attachmentBehaviors allKeys];
}



@end
