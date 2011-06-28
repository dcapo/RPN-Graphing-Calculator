//
//  GraphView.m
//  GraphingCalculator
//
//  Created by Daniel Capo.
//  Copyright 2011. All rights reserved.
//

#import "GraphView.h"
#import "AxesDrawer.h"

@interface GraphView()
@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) CGPoint translation;
@end

@implementation GraphView

@synthesize delegate, scaleFactor, translation, dotMode;

// To make dotmode look a little more continuous over large leaps in Y, plot
// more x values using this delta-value. 
#define DOTMODE_DELTA_X 5
// Default scale of the graph for first time use of the app. 
#define DEFAULT_SCALE 14

-(void)setup 
{
    //when the bounds change, redraw graphView
    self.contentMode = UIViewContentModeRedraw;
}

//just in case graphView is loaded from a nib
-(void)awakeFromNib 
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) { 
        CGFloat storedScaleFactor = [[NSUserDefaults standardUserDefaults] floatForKey:@"scaleFactor"];
        // if this is the first run of the application, set scaleFactor to
        // DEFAULT_SCALE; else set it to the storedScaleFactor
        self.scaleFactor = (storedScaleFactor > 0) ? storedScaleFactor : DEFAULT_SCALE;
        self.translation = CGPointMake([[NSUserDefaults standardUserDefaults] floatForKey:@"translation.x"],[[NSUserDefaults standardUserDefaults] floatForKey:@"translation.y"]);
        [self setup];
        self.dotMode = NO;
    }
    return self;
}

//custom setter method stores any newTranslation values to standardUserDefaults
-(void)setTranslation:(CGPoint)newTranslation {
    translation = newTranslation;
    [[NSUserDefaults standardUserDefaults] setFloat: translation.x forKey:@"translation.x"];
    [[NSUserDefaults standardUserDefaults] setFloat: translation.y forKey:@"translation.y"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setNeedsDisplay];
}

//custom setter method stores any newScaleFactor values to standardUserDefaults
- (void)setScaleFactor:(CGFloat)newScaleFactor
{
    scaleFactor = newScaleFactor;
    [[NSUserDefaults standardUserDefaults] setFloat: scaleFactor forKey:@"scaleFactor"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setNeedsDisplay];
}

// restore the coordinate system origin to the center of the view with a double-tap
-(void)tap:(UITapGestureRecognizer *)gesture 
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        self.translation = CGPointMake(0,0);    
    }
}

// update the translation of the origin when the user pans
-(void)pan:(UIPanGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint offset = [gesture translationInView:self];
        self.translation = CGPointMake(self.translation.x + offset.x, self.translation.y + offset.y);
        [gesture setTranslation:CGPointZero inView:self];
    }
}

// update the zoom when the user pinches
- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        self.scaleFactor *= gesture.scale;
        gesture.scale = 1.0;
    }
}


// drawRect handles the drawing of the program graph. It uses contentScaleFactor to 
// iterate over pixels, as opposed to points.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect axesRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    CGContextSetLineWidth(context, 2.0);
	[[UIColor blackColor] setStroke];
    CGPoint midPoint = CGPointMake(self.bounds.origin.x + self.bounds.size.width/2, 
                                   self.bounds.origin.y + self.bounds.size.height/2);
    CGPoint currentOrigin = CGPointMake(midPoint.x + translation.x, midPoint.y + translation.y);
    [AxesDrawer drawAxesInRect: axesRect originAtPoint:currentOrigin scale:self.scaleFactor];
    //graphX denotes the x-value of the graph coordinate space, as opposed to that of the screen. 
    CGFloat graphX = (0 - currentOrigin.x)/self.scaleFactor;
    CGFloat graphY = [self.delegate yValue:self fromXValue:graphX];
    CGFloat pointY = currentOrigin.y - (graphY * self.scaleFactor);
    CGFloat pixelSize = 1/self.contentScaleFactor;
    
    // I did not have time to implement the Dot Mode UISwitch programatically
    // (that is, because we had to remove the .xib), but I have left the code
    // for dot mode in case I want to use it later on. 
    if (self.dotMode == YES) {
        CGRect dot = CGRectMake(0, pointY, 2*pixelSize, 2*pixelSize);
        [[UIColor redColor] setFill];
        CGContextFillRect(context, dot);
        //for every pixel/DOTMODE_DELTA_X in the width of the screen, draw the appropriate y-value
        for (CGFloat pointX = pixelSize; pointX < self.bounds.size.width; pointX += pixelSize/DOTMODE_DELTA_X) {
            graphX = (pointX - currentOrigin.x)/self.scaleFactor;
            graphY = [self.delegate yValue:self fromXValue:graphX];
            pointY = currentOrigin.y - (graphY * self.scaleFactor); 
            dot = CGRectMake(pointX, pointY, 2*pixelSize, 2*pixelSize);
            CGContextFillRect(context, dot);
        }
    } else {
        CGContextMoveToPoint(context, 0, pointY);
        //for every pixel in the width of the screen, draw the appropriate y-value
        for (CGFloat pointX = 1/self.contentScaleFactor; pointX < self.bounds.size.width; pointX+= 1/self.contentScaleFactor) {
            graphX = (pointX - currentOrigin.x)/self.scaleFactor;
            graphY = [self.delegate yValue:self fromXValue:graphX];
            pointY = currentOrigin.y - (graphY * self.scaleFactor);    
            CGContextAddLineToPoint(context, pointX, pointY);
        }
        [[UIColor redColor] setStroke];
        CGContextDrawPath(context,kCGPathStroke);
        
    }
}

- (void)dealloc
{
    [super dealloc];
}

@end
