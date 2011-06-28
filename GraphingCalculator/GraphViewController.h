//
//  GraphViewController.h
//  GraphingCalculator
//
//  Created by Daniel on 4/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"


@interface GraphViewController : UIViewController <GraphViewDelegate, UISplitViewControllerDelegate> {}

// This is initialized to the program passed to the controller by graphPressed in the CalculatorViewController.
@property (nonatomic, retain) NSArray *program;
// We need this to display the name of the function (i.e. y = x) in the title bar. 
@property (nonatomic, retain) NSString *description; 

@end
