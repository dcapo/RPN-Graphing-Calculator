//
//  GraphView.h
//  GraphingCalculator
//
//  Created by Daniel on 4/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphView;

//This method must be implemented by the delegate, GraphViewController
@protocol GraphViewDelegate
- (CGFloat) yValue:(GraphView *)sender fromXValue:(CGFloat) xValue;
@end

@interface GraphView : UIView
//The scale of the graph:
@property (nonatomic, assign) id <GraphViewDelegate> delegate;
//The state of the UISwitch for Dot Mode
@property (nonatomic) BOOL dotMode;

@end
