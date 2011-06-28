//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Daniel.
//  Copyright 2011. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()
@property (nonatomic, readonly, retain) NSMutableArray *programStack;
@end

//CalculatorBrain is the calculator's model. It handles the performance of the actual mathematical operations.
@implementation CalculatorBrain

@synthesize programStack, program;

// provide our own getter to do lazy instantiation
- (NSMutableArray *)programStack
{
    if (!programStack) {
        programStack = [[NSMutableArray alloc] init];
    }
    return programStack;
}

// pushOperand places the double 'operand' on the program stack.
-(void)pushOperand:(id)operand
{
    if ([operand isKindOfClass:[NSNumber class]])
    {
        NSNumber *operandObject = operand;
        [self.programStack addObject:operandObject];
    } else {
        NSString *variable = operand;
        [self.programStack addObject:variable];
    }
}

// clearProgram wipes the program's history.
-(void)clearProgram
{
    [programStack release];
    programStack = nil;
}

//This class method returns YES if the NSString parameter is a variable.
+(BOOL) isVariable:(NSString *)operand {
    return [operand isEqual:@"a"] || [operand isEqual:@"b"]|| [operand isEqual:@"x"];
}

// getOperationArity returns the number of operands that 'operation' requires.
+ (int) getOperationArity:(NSString *)operation {
    NSSet *setOfOperationsWithArityOne = [NSSet setWithObjects: @"√", @"sin", @"cos", @"tan", nil];
    NSSet *setOfOperationsWithArityTwo = [NSSet setWithObjects: @"+", @"-", @"*", @"/", nil];
    if ([setOfOperationsWithArityOne containsObject:operation]) return 1;
    if ([setOfOperationsWithArityTwo containsObject:operation]) return 2;
    return 0;
}

// As part of the implementation for the 'undo' button, this method removes
// the top item from the stack.
-(void) removeTopItemFromProgramStack
{
    if ([self.programStack count] != 0) [self.programStack removeObjectAtIndex:[self.programStack count] - 1];
}

/* It is not specified if we have to handle the edge case where a user inputs an operation when it cannot be
   accepted by the program (e.g. 2E+ or 2E3++). Paul's code adds operations to the stack even when they are
   illegal, so I don't know if this is necessary. I would really appreciate some guidance how to tackle this.
+(BOOL) newOperation: (NSString *)operation CanBeAdded: (id)programLocal {
    int operandCount = 0;
    int operationCount = 0;
    if ([programLocal isKindOfClass:[NSArray class]]) {
        NSArray *programArray = programLocal;
        for (int i = 0; i < [programArray count]; i++) {
            if ([[programArray objectAtIndex:i] isKindOfClass:[NSString class]]) {
                NSString *variableCandidate = [programArray objectAtIndex:i];
                if ([self isVariable: variableCandidate]) {
                    operandCount++;
                } else {
                    operationCount += [self getOperationArity:variableCandidate];
                }
            } else operandCount++;
        }
    }
    return operandCount >= (operationCount + [self getOperationArity:operation]);
}*/

// performOperation is called everytime an operation is pressed. It adds the operation
// to the program stack and then returns the value of a program run.
// Note: this returned value is not captured in the controller! I don't understand why
// this function has to return a double. 
- (double)performOperation:(NSString *)operation
{
    [self.programStack addObject:operation];
    return [CalculatorBrain runProgram:self.program];
}

// return our internal data structure, but copy it first to protect it (and manage the memory right)
// caller has no idea this is a copy of our internal data structure
// caller can only use this to call the two class methods (runProgram: and descriptionOfProgram:)
- (id)program
{
    return [[self.programStack copy] autorelease]; // copy has "copy" in it, so we own this, must autorelease
}


//returns a set of the variable names that have been input into the program.
+ (NSMutableSet *)variablesUsedInProgram:(id)program {
    NSMutableSet *variablesUsed = [[NSMutableSet alloc]init ];
    if ([program isKindOfClass:[NSArray class]]) {
        NSArray *programArray = program;
        for (int i = 0; i < [programArray count]; i++) {
            if ([[programArray objectAtIndex:i] isKindOfClass:[NSString class]]) {
                NSString *variableCandidate = [programArray objectAtIndex:i];
                if ([self isVariable: variableCandidate]) {
                    [variablesUsed addObject:variableCandidate];
                }
            }
        }
    }
    [variablesUsed autorelease];
    return variablesUsed;
}

/*popOperandOffProgramStack is the recursive step in runProgram. It goes through
 all the items in the stack and performs the necessary operations to return a
 value for the most recent independent expression (i.e. the last expression, as 
 separated by commas in the description label. 
 */
+ (double)popOperandOffProgramStack:(NSMutableArray *)stack
{
    double result = 0;
    id topOfStack = [stack lastObject];
    [topOfStack retain]; // retain because removeLastObject might be the last owner's release
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        result = [topOfStack doubleValue];
    } else if ([topOfStack isKindOfClass:[NSString class]])
    {
        NSString *operator = topOfStack;
        if ([operator isEqualToString:@"+"]) {
            result = [self popOperandOffProgramStack:stack] +
            [self popOperandOffProgramStack:stack];
        } else if ([operator isEqualToString:@"*"]) {
            result = [self popOperandOffProgramStack:stack] *
            [self popOperandOffProgramStack:stack];
        } else if ([operator isEqualToString:@"-"]) {
            result = - [self popOperandOffProgramStack:stack] +
            [self popOperandOffProgramStack:stack];
        } else if ([operator isEqualToString:@"/"]) {
            double divisor = [self popOperandOffProgramStack:stack];
            if (divisor) result = [self popOperandOffProgramStack:stack] / divisor;
        } else if ([operator isEqualToString:@"sin"]) {
            result = sin([self popOperandOffProgramStack:stack]);
        } else if ([operator isEqualToString:@"cos"]) {
            result = cos([self popOperandOffProgramStack:stack]); 
        } else if ([operator isEqualToString:@"tan"]) {
            result = tan([self popOperandOffProgramStack:stack]);  
        } else if ([operator isEqualToString:@"√"]) {
            result = sqrt([self popOperandOffProgramStack:stack]);
        } else if ([operator isEqualToString:@"π"]) {
            result = M_PI;
        }
    }
    
    [topOfStack release]; // we "retain"ed above, so we must release before we go
    return result;
}

// run the program (i.e. replay operand entry and operations)
// protects against "junk" via introspection
+ (double)runProgram:(id)program
{
    double result = 0;
    id mutableProgram = nil;
    
    if ([program isKindOfClass:[NSArray class]]) {
        mutableProgram = [program mutableCopy]; // mutableCopy has "copy" in it, so we own this
        result = [self popOperandOffProgramStack:mutableProgram];
    }
    
    [mutableProgram release]; // we own this, so we must give up ownership before we return
    return result;
}

// This method goes through 'program' and replaces all instances of variables with
// their appropriate double values, as determined by the dictionary variableValues.
+ (id) replaceVariablesInProgram: (id)program withValues: (NSDictionary *) variableValues {
    NSMutableArray *programArray = program;
    for (int i = 0; i< [programArray count]; i++) {
        id stackElement = [programArray objectAtIndex:i];
        if ([stackElement isKindOfClass:[NSString class]]) {
            NSString *elementString = stackElement;
            NSNumber *variableValue = [NSNumber numberWithDouble: 0];
            if ([self isVariable:elementString]) {
                if (variableValues) {
                    if ([variableValues objectForKey:elementString]) {
                        variableValue = [variableValues objectForKey:elementString];
                    }
                }
                [programArray replaceObjectAtIndex:i withObject: variableValue];
            }
        }
    }
    return programArray;
}

// runProgram:usingVariableValues is identical to runProgram, with the exception that
// it calls replaceVariableValuesInProgram:withValues
+ (double)runProgram:(id)program usingVariableValues:(NSDictionary *)variableValues {
    double result = 0;
    id mutableProgram = nil;
    
    if ([program isKindOfClass:[NSArray class]]) {
        mutableProgram = [program mutableCopy]; 
        mutableProgram = [self replaceVariablesInProgram:mutableProgram withValues: variableValues];
        result = [self popOperandOffProgramStack:mutableProgram];
    }
    [mutableProgram release];
    return result;
}

/* descriptionOfTopOfProgramStack is the recursive step in printing the human-readable
   description of the program. It only returns a description of the most recent
   independent expression.
*/
+ (NSString *)descriptionOfTopOfProgramStack:(NSMutableArray *)programArray {
    NSString *topDescription = nil;
    id topOfStack = [programArray lastObject];
    [topOfStack retain];
    if (topOfStack) [programArray removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        NSNumber *operand = topOfStack;
        topDescription = [NSString stringWithFormat: @"%@", operand];
    } else if ([topOfStack isKindOfClass:[NSString class]]) {
        NSString *stackTopString = topOfStack;
        int operationArity = [self getOperationArity:stackTopString];
        // operationArity is 0 for both variables and 0-arity operations.
        if (operationArity == 0) topDescription = stackTopString;
        if (operationArity == 1) topDescription = [NSString stringWithFormat:@"(%@(%@))", stackTopString,
                                                   [self descriptionOfTopOfProgramStack:programArray]];
        if (operationArity == 2) {
            NSString *rightExpression = [self descriptionOfTopOfProgramStack:programArray];
            NSString *leftExpression = [self descriptionOfTopOfProgramStack:programArray];
            topDescription = [NSString stringWithFormat: @"(%@ %@ %@)", 
                              leftExpression, stackTopString, rightExpression];             
        }    
    }
    [topOfStack release];
    return topDescription;
}

// Eliminates the unnecessary, outermost nesting of parentheses.
+ (NSString *)getRidOfOutermostParentheses: (NSString*)description {
    // if there is an open-parenthesis, this expression is more complex than just a
    // variable or number.
    if ([description hasPrefix: @"("]) {
        description = [description substringFromIndex:1];
        description = [description substringToIndex: [description length] - 1];
        
    }
    return description;
}

// This is the wrapper function for the recursive step, descriptionOfTopOfProgramStack.
+ (NSString *)descriptionOfProgram:(id)program
{
    NSString *description = @"";
    NSMutableArray *programArray;
    if ([program isKindOfClass:[NSArray class]]) {
        programArray = [program mutableCopy];
        description = [self getRidOfOutermostParentheses:[self descriptionOfTopOfProgramStack:programArray]];
        // if there is more to evaluate in the stack, form a description for this, too,
        // by calling the recursive step again, and append the first description to it.
        while ([programArray count] != 0) {
            NSString *penultimateExpression = [self getRidOfOutermostParentheses:[self descriptionOfTopOfProgramStack:programArray]];;
            description = [NSString stringWithFormat:@"%@, %@", 
                           penultimateExpression, description];
        }
    }
    [programArray release];
    return description;
}

// release ownership of our instance variables
- (void)dealloc
{
    [programStack release];
    [super dealloc];
}


@end
