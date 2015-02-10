//
//  ViewController.m
//  Carousel
//
//  Created by R_style Man on 15-1-21.
//  Copyright (c) 2015年 R_style Man. All rights reserved.
//

#import "ViewController.h"
#import "SCCollectionViewSampleCell.h"
#import "SCItemBehaviorManager.h"

#pragma mark - SCSpringyCarousel

@interface SCSpringyCarousel : UICollectionViewFlowLayout
{
    CGSize _itemSize;
    SCItemBehaviorManager* _behaviorManager;
}
@property (strong,nonatomic) UIDynamicAnimator* dynamicAnimator;

-(instancetype)initWithItemSize:(CGSize)size;

@end

@implementation SCSpringyCarousel

-(instancetype)initWithItemSize:(CGSize)size
{
    self = [super init];
    if (self)
    {
        _itemSize = size;
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        _behaviorManager = [[SCItemBehaviorManager alloc] initWithAnimator:_dynamicAnimator];
    }
    return self;
}

-(void) prepareLayout
{
    self.sectionInset = UIEdgeInsetsMake(CGRectGetHeight(self.collectionView.bounds) - _itemSize.height, 0, 0, 0);
    [super prepareLayout];
    
    [UIView setAnimationsEnabled:NO];
    
    //Get a list of the objects around the current view
    CGRect expandedViewPort = self.collectionView.bounds;
    expandedViewPort.origin.x -= 2 * _itemSize.width;
    expandedViewPort.size.width += 4* _itemSize.width;
    NSArray* currentItems = [super layoutAttributesForElementsInRect:expandedViewPort];
    
    // We update our behavior collection to contain the items we can currently see
    [_behaviorManager updateItemCollection:currentItems];
}

-(BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGFloat scrollDelta = newBounds.origin.x - self.collectionView.bounds.origin.x;
    //NSLog(@"%f",self.collectionView.bounds.origin.x);
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    for (UIAttachmentBehavior* bhvr in [_behaviorManager.attachmentBehaviors allValues])
    {
        CGPoint anchorPoint = bhvr.anchorPoint;
        CGFloat distFormTouch = ABS(anchorPoint.x - touchLocation.x);
        
        UICollectionViewLayoutAttributes* attr = [bhvr.items firstObject];
        CGPoint center = attr.center;
        CGFloat scrollFactor = MIN(1, distFormTouch/500);
        
        center.x += scrollDelta* scrollFactor;
        attr.center = center;
        
        [_dynamicAnimator updateItemUsingCurrentState:attr];
    }
    
    return NO;
}

-(NSArray*) layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_dynamicAnimator itemsInRect:rect];
}

-(UICollectionViewLayoutAttributes*) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
}

#pragma mark - insert methods delegate

-(UICollectionViewLayoutAttributes*) initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    return [_dynamicAnimator layoutAttributesForCellAtIndexPath:itemIndexPath];
}

// override the  prepareForCollectionViewUpdates:

-(void) prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    for (UICollectionViewUpdateItem* updateItem in updateItems)
    {
        if (updateItem.updateAction == UICollectionUpdateActionInsert)
        {
            // Reset the springs of the existing items
            [self resetItemSpringsForInsertAtIndexpath:updateItem.indexPathAfterUpdate];
            
            // Where woule the flow layout like to place the new cell?
            UICollectionViewLayoutAttributes* attr = [super initialLayoutAttributesForAppearingItemAtIndexPath:updateItem.indexPathAfterUpdate];
            CGPoint center = attr.center;
            CGSize contentSize = [self collectionViewContentSize];
            center.y -= contentSize.height - CGRectGetHeight(attr.bounds);
            
            // Now reset the center of insertion point for the animator
            UICollectionViewLayoutAttributes* insertionPointAttr = [self layoutAttributesForItemAtIndexPath:updateItem.indexPathAfterUpdate];
            insertionPointAttr.center = center;
            // 改变center等物理参数对view的动态效果的影响
            [_dynamicAnimator updateItemUsingCurrentState:insertionPointAttr];
        }
    }
}

// update the springs of the items ,oved to make space for the new item

-(void) resetItemSpringsForInsertAtIndexpath:(NSIndexPath*) indexPath
{
    // Get a list of items, sorted by their indexpath
    NSArray* items = [_behaviorManager currentlyManagedItemPaths];
    // Now loop backwards, updating centers appropriately.
    // We need to get 2 enumerators - copy from one to the other.
    
    
    // 反向枚举的研究
    NSEnumerator* fromEnumerator = [items reverseObjectEnumerator];
    // We want to skip the lastmost object in the array as we're copying left to right
    [fromEnumerator nextObject];
    // Now enumarate the array -  through the 'to' positions
    [items enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath* toIndex = (NSIndexPath*) obj;
        NSIndexPath* fromIndex = (NSIndexPath*)[fromEnumerator nextObject];
        
        // If the 'from' cell is after the insert then need to reset the springs
        
        if (fromIndex && fromIndex.item >= indexPath.item)
        {
            UICollectionViewLayoutAttributes* toItem = [self layoutAttributesForItemAtIndexPath:toIndex];
            UICollectionViewLayoutAttributes* fromItem = [self layoutAttributesForItemAtIndexPath:fromIndex];
            toItem.center = fromItem.center;
            [_dynamicAnimator updateItemUsingCurrentState:toItem];
        }
    }];
}

@end

#pragma mark - viewController

@interface ViewController ()
{
    NSMutableArray* _collectionViewCellContent;
    CGSize itemSize;
    SCSpringyCarousel* _collectionViewLayout;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    itemSize = CGSizeMake(50, 50);
    _collectionViewLayout = [[SCSpringyCarousel alloc] initWithItemSize:itemSize];
    _collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView.collectionViewLayout = _collectionViewLayout;
    _collectionViewCellContent = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<100; i++)
    {
        NSString* s = [NSString stringWithFormat:@"%d",i];
        [_collectionViewCellContent addObject:s];
    }
    
}

-(IBAction)newViewButtonPressed:(UIButton*)btn
{
    // What's the new number we're creating?
    NSNumber* newTitle = @([_collectionViewCellContent count]);
    
    // We want to place it in at the correct position
    NSIndexPath* rightOfCenter = [self indexPathOfItemRightOfCenter];
    
    // Insert the new item content
    [_collectionViewCellContent insertObject:[newTitle stringValue] atIndex:rightOfCenter.item];
    
    // Redraw
    [self.collectionView insertItemsAtIndexPaths:@[rightOfCenter]];
}

// 计算 center
-(NSIndexPath*) indexPathOfItemRightOfCenter
{
    // Find all the currentley visible items
    NSArray* visibleItems = [self.collectionView indexPathsForVisibleItems];
    
    // Calculate the middle of the current collection view content
    CGFloat midX = CGRectGetMidX(self.collectionView.bounds);
    NSUInteger indexOfItem = 0 ;
    CGFloat curMin = CGFLOAT_MAX;
    
    // Loop through the visible cells to find the left of center one
    for (NSIndexPath* indexPath in visibleItems)
    {
        UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        
        if (ABS(CGRectGetMidX(cell.frame) - midX) < ABS(curMin))
        {
            curMin = CGRectGetMidX(cell.frame) - midX;
            indexOfItem = indexPath.item;
        }
    }
    
    // If min is -ve then we have left of center, if +ve then we have right of center.
    if (curMin < 0)
    {
        indexOfItem += 1;
    }
    
    // And now get the index path to pass back
    return [NSIndexPath indexPathForItem:indexOfItem inSection:0];
    
}

#pragma mark - UICollectionViewDataSource methods
-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _collectionViewCellContent.count;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCCollectionViewSampleCell* cell = (SCCollectionViewSampleCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"SpringyCell" forIndexPath:indexPath];
    
    cell.numbleLabel.text = [NSString stringWithFormat:@"%ld",[_collectionViewCellContent[indexPath.row] integerValue]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return itemSize;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
