//
//  GraphViewController.m
//  GraphingCalculator
//
//  Created by Daniel.
//  Copyright 2011. All rights reserved.
//

#import "GraphViewController.h"
#import "CalculatorBrain.h"

@interface GraphViewController()
@property (nonatomic, retain) IBOutlet GraphView *graphView;
@end


@implementation GraphViewController {}

@synthesize graphView, program, description;

- (GraphView *)graphView
{
    if (!graphView) {
        graphView = [[GraphView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
        graphView.backgroundColor = [UIColor whiteColor];
        self.graphView.delegate = self;
    }
    return graphView;
}   


//custom setter for graphView, so that we can reset this controller as graphView's delegate.
- (void)setGraphView:(GraphView *)newGraphView
{
    [newGraphView retain];
    [graphView release];
    graphView = newGraphView;
    self.graphView.delegate = self;
    [self.graphView setNeedsDisplay];
}

//functionName returns the name of the graphed function, for the controller's title bar (e.g. "y = sin(x)")
-(NSString *)functionName {
    NSArray *components = [description componentsSeparatedByString:@","];
    //We are only interested in capturing the last string after the last comma in programDescription
    NSString *function = [NSString stringWithFormat: @"y = %@", [components objectAtIndex:[components count] - 1]];
    return function;
}

- (void) setProgram:(NSArray *)newProgram 
{
    if (program != newProgram) { 
        [program release];
        program = [newProgram retain];
        self.title = [self functionName];
        [self.graphView setNeedsDisplay];
    }
}

// This could be used to switch to dot mode if the UISwitch existed without the .xib file...
- (IBAction)switchPressed:(id)sender {
    self.graphView.dotMode = !(self.graphView.dotMode);
    [self.graphView setNeedsDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// This is the protocol method that is delegated to this controller by graphView. It runs the program
// with xValue set as the x variable value in variableValueDictionary. It then returns
// the result of the program run as the corresponding yValue. 
- (CGFloat) yValue:(GraphView *)sender fromXValue:(CGFloat) xValue {
    NSDictionary *variableValueDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat: xValue], @"x", nil];
    return [CalculatorBrain runProgram: self.program usingVariableValues:variableValueDictionary];
}


#pragma mark - UISplitViewControllerDelegate implementation


// This is called when we switch from landscape to portrait.
// The aViewController is being hidden and the barButtonItem
//   is suitable for us to put in our UI to bring aViewController's
//   view up in a popover.
// This is completely generic.
// It does not matter what kind of controller aViewController is.
- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = aViewController.title;
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

// This is called when we switch from portrait to landscape.
// All we need to do is remove the button from our UI because
//   now the aViewController is on screen with us side-by-side.
- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}

#pragma mark - View lifecycle

- (void)loadView {
    self.view = self.graphView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [self functionName];
     //add the pinch zoom to graphView
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(pinch:)];
    [self.graphView addGestureRecognizer:pinchGesture];
    [pinchGesture release];
    //add the pan origin translation to this controller
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(pan:)];
    [self.graphView addGestureRecognizer:panGesture];
    [panGesture release];
    //add the double-tap translation to this controller
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.graphView action:@selector(tap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.graphView addGestureRecognizer:doubleTapGesture];
    [doubleTapGesture release];
    
}

- (void)viewDidUnload
{
    self.graphView = nil;
    self.program = nil;
    self.description = nil; 
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)dealloc
{
    [graphView release];
    [program release];
    [description release];
    [super dealloc];
}

@end
