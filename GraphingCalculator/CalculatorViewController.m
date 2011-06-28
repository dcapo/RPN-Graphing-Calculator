//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Daniel.
//  Copyright 2011. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"
#import "GraphViewController.h"

#define POPOVER_MARGIN 100

@interface CalculatorViewController()
@property (readonly) CalculatorBrain *brain;
@property (nonatomic, retain) NSDictionary *testVariableValues;
@property BOOL userIsInTheMiddleOfTyping;
@property BOOL floatingPointAlreadyExists;
//This is the outlet to the calculator's display, located at the top of the view.
@property (retain) IBOutlet UILabel *display;
@property (retain) IBOutlet UILabel *programDescription;
@property (readonly) BOOL iPad;
- (IBAction)enterPressed;
@end

@implementation CalculatorViewController { }

@synthesize brain, testVariableValues, userIsInTheMiddleOfTyping, floatingPointAlreadyExists;
@synthesize display, programDescription;
@synthesize graphViewController;

- (GraphViewController *)graphViewController
{
    if (!graphViewController) graphViewController = [[GraphViewController alloc] init];
    return graphViewController;
}

/* This action is called when a digit is pressed. The display is updated accordingly.
 It also treats a decimal point as a digit, and only allows the user to input a 
 decimal point when it is legal to do so. 
 */
- (IBAction)digitPressed:(UIButton *)sender 
{
    NSString *digit = sender.currentTitle;
    if (self.userIsInTheMiddleOfTyping) {
        /*add the digit to the string already on the display, if it is not a floating point, 
         or if it is legal to add a floating point.*/
        if (![digit isEqual:@"."] || self.floatingPointAlreadyExists == NO) {
            display.text = [display.text stringByAppendingString:digit];
        }
    } else if (![digit isEqual:@"0"]) {
        display.text = digit;
        self.userIsInTheMiddleOfTyping = YES;  
    }
    //if the digit is a decimal point, update the BOOL to indicate that a decimal exists.
    if ([digit isEqual:@"."]) self.floatingPointAlreadyExists = YES;
}

// Custom getter method: initializes the dictionary if it is nil
- (NSDictionary *)testVariableValues
{
    if (!testVariableValues) testVariableValues = [[NSDictionary alloc] init];
    return testVariableValues;
}

- (CalculatorBrain *)brain
{
    if (!brain) brain = [[CalculatorBrain alloc] init];
    return brain;
}


// Returns true if the string 'operand' is a variable.
-(BOOL) isVariable:(NSString *)operand {
    return [operand isEqual:@"x"];
}

// updateUI runs the current program, updates the display, and also updates the
// program description. 
- (void)updateUI
{
    id program = self.brain.program;
    if (!self.userIsInTheMiddleOfTyping) {
        //double runResult = [CalculatorBrain runProgram:program];
        double runResult = [CalculatorBrain runProgram:program usingVariableValues: self.testVariableValues];
        display.text = [NSString stringWithFormat:@"%g", runResult];
    }
    programDescription.text = [CalculatorBrain descriptionOfProgram:program];
}


//enterPressed pushes the operand on the display onto the stack. 
- (IBAction)enterPressed
{
    if ([self isVariable:display.text]) {
        [self.brain pushOperand:display.text];
    } else {
        NSNumber *numericalOperand = [NSNumber numberWithDouble:[display.text doubleValue]];
        [self.brain pushOperand:numericalOperand];
    }
    [self updateUI];
    self.userIsInTheMiddleOfTyping = NO;
    self.floatingPointAlreadyExists = NO;
}


// clearPressed clears the operand stack and reinitializes the screen to zero.
- (IBAction)clearPressed 
{
    [self.brain clearProgram];
    self.testVariableValues = nil;
    display.text = @"0";
    [self updateUI];
    self.userIsInTheMiddleOfTyping = NO;
}

// undoPressed eliminates the last digit (or decimal) in the number on the display,
// and beyond that, retraces steps in the program's entry. 
- (IBAction)undoPressed:(id)sender {
    if (userIsInTheMiddleOfTyping) {
        if ([display.text length] > 1) {
            if ([display.text characterAtIndex:[display.text length] - 1] == '.') {
                floatingPointAlreadyExists = NO;
            }
            display.text = [display.text substringToIndex: [display.text length] -1];
        } else {
            userIsInTheMiddleOfTyping = NO;
            [self updateUI];
        }
    } else {
        [self.brain removeTopItemFromProgramStack];
        [self updateUI];
    }
}


// Handles pushing variables onto the stack.
- (IBAction)variablePressed:(UIButton *)sender {
    if (self.userIsInTheMiddleOfTyping) [self enterPressed];
    display.text = sender.currentTitle;
    [self.brain pushOperand:display.text];
    [self updateUI];
    self.userIsInTheMiddleOfTyping = NO;
}


//operationPressed calls the model (or brain) to perform the appropriate operation.
- (IBAction)operationPressed:(UIButton *)sender 
{
    if (self.userIsInTheMiddleOfTyping) [self enterPressed];
    [self.brain performOperation:sender.currentTitle];
    [self updateUI];
}

// graphPressed pushes the graphViewController if we are on an iPhone only. 
// Regardless of the platform, it updates graphView. 
- (IBAction)graphPressed:(UIButton *)sender {
    GraphViewController *gvc = self.graphViewController;
    gvc.description = programDescription.text;
    gvc.program = self.brain.program;
    if (!gvc.view.window) [self.navigationController pushViewController:gvc animated:YES];
}


#pragma mark - View lifecycle

// Paul's hint says that "if I'm on an iPad/iPhone" is not the best test for autorotation, 
// but I don't exactly see what's wrong with it. A little explanation here would be greatly appreciated!
- (BOOL)iPad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)anOrientation
{
    if(self.iPad) return YES;
    // We do not want calculatorView to rotate to landscape on an iPhone
    else return (anOrientation == UIInterfaceOrientationPortrait);
}

// contentSizeForViewInPopover iterates through the subviews of CalculatorViewController, builds
// up a CGRect of a size that captures all the subviews, and then returns the size of the CGRect 
// (with margins added). 
- (CGSize)contentSizeForViewInPopover
{
    CGRect biggestRect = CGRectNull;
    BOOL firstIteration = YES;
    //minx and minY are the margins
    CGFloat minX, minY;
    for (UIView *subview in self.view.subviews) {
        if (firstIteration) {
            minX = subview.frame.origin.x;
            minY = subview.frame.origin.y;
            firstIteration = NO;
        } else {
            if (subview.frame.origin.x < minX) minX = subview.frame.origin.x; 
            if (subview.frame.origin.y < minY) minY = subview.frame.origin.y;
        }  
        //keep building up the size of biggestRect, which will contain all the subviews
        biggestRect = CGRectUnion(biggestRect, subview.frame);
    }
    return CGSizeMake(biggestRect.size.width + 2*minX, biggestRect.size.height + 2*minY);
}

- (void)viewDidLoad
{
    self.title = @"Graphing Calculator";
}

- (void)viewDidUnload {
    self.display = nil;
    self.programDescription = nil;
    [super viewDidUnload];
}

- (void)dealloc
{
    [brain release]; 
    [testVariableValues release];
    [display release];
    [programDescription release];
    [graphViewController release];
    [super dealloc];
}

@end
