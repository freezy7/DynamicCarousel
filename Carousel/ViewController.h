//
//  ViewController.h
//  Carousel
//
//  Created by R_style Man on 15-1-21.
//  Copyright (c) 2015年 R_style Man. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (weak,nonatomic) IBOutlet UICollectionView* collectionView;

@end

