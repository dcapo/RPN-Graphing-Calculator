//
//  CalculatorBrain.h
//  Calculator
//
//  Created by Daniel.
//  Copyright 2011. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CalculatorBrain : NSObject

//pushOperand places 'operand' on the operand stack.
- (void)pushOperand:(id)operand;

/*performOperation is where the math occurs for all operations. It takes as
 a parameter the button label's text for the respective operation. 
 */
- (double)performOperation:(NSString *)operation;

//clearOperandStack removes all the operands on the stack.
- (void)clearProgram;

//remove the operand or operation most recently added to the program stack
- (void)removeTopItemFromProgramStack;

@property (readonly) id program;

/* descriptionOfProgram handles the human-readable presentation of 
 the programStack. It returns a string, which is used to update the 
 label that is just above the calculator's buttons.*/
+ (NSString *)descriptionOfProgram:(id)program; 

// "replays" operand entry and operations and returns the value of the most recent
// independent expression (i.e. what to show in the calculator's display).
+ (double)runProgram:(id)program;   

// This method is the same as runProgram, except it substitutes values for variables,
// as determined by the contents of the dictionary parameter, variableValues
+ (double)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues;

// This method returns a set of all the variables used in the current program. 
+ (NSMutableSet *)variablesUsedInProgram:(id)program;

@end
