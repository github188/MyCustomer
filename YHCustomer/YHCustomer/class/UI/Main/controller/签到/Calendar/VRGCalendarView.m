//
//  VRGCalendarView.m
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//

#import "VRGCalendarView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+convenience.h"
#import "NSMutableArray+convenience.h"
#import "UIView+convenience.h"

@implementation VRGCalendarView
@synthesize currentMonth,delegate,labelCurrentMonth, animationView_A,animationView_B;
@synthesize markedDates,markedColors,calendarHeight,selectedDate;
@synthesize todayStr;
#pragma mark - Select Date
-(void)selectDate:(int)date
{
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:self.currentMonth];
    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];
    
    NSInteger selectedDateYear = [selectedDate year];
    NSInteger selectedDateMonth = [selectedDate month];
    NSInteger currentMonthYear = [currentMonth year];
    NSInteger currentMonthMonth = [currentMonth month];
    
    if (selectedDateYear < currentMonthYear) {
        [self showPreviousMonth];
    } else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
    } else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
    } else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    } else {
        [self setNeedsDisplay];
    }
    
    if ([delegate respondsToSelector:@selector(calendarView:dateSelected:)]) [delegate calendarView:self dateSelected:self.selectedDate];
}

#pragma mark - Mark Dates
//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates
{
    self.markedDates = dates;
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<[dates count]; i++) {
        [colors addObject:[UIColor colorWithHexString:@"0x383838"]];
    }
    self.markedColors = [NSArray arrayWithArray:colors];
    [colors release];
    
    [self setNeedsDisplay];
}

//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors
{
    self.markedDates = dates;
    self.markedColors = colors;
    [self setNeedsDisplay];
}

#pragma mark - Set date to now
-(void)reset
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];//格式化
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"] ];
    NSDate *date =[[NSDate alloc]init];
    date =[df dateFromString:todayStr];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
                           NSDayCalendarUnit) fromDate:date];
    self.currentMonth = [gregorian dateFromComponents:components]; //clean month
//    NSChineseCalendar
    [self updateSize];
    [self setNeedsDisplay];
    [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
}

#pragma mark - Next & Previous
-(void)showNextMonth
{
    if (isAnimating) return;
    self.markedDates=nil;
    isAnimating=YES;
    prepAnimationNextMonth=YES;
    
    [self setNeedsDisplay];
    
    NSUInteger lastBlock = [currentMonth firstWeekDayInMonth]+[currentMonth numDaysInMonth];
    int numBlocks = [self numRows]*7;
    BOOL hasNextMonthDays = lastBlock<numBlocks;
    
    //Old month
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //New month
    self.currentMonth = [currentMonth offsetMonth:1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight: animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationNextMonth=NO;
    [self setNeedsDisplay];
    
    UIImage *imageNextMonth = [self drawCurrentState];
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    [animationHolder release];
    
    //Animate
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imageNextMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasNextMonthDays) {
//        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight - (kVRGCalendarViewDayHeight+3);
        animationView_B.frameX = [UIScreen mainScreen].bounds.size.width;
    } else {
//        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight -3;
        animationView_B.frameX = [UIScreen mainScreen].bounds.size.width;
    }
    
    //Animation
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         //blockSafeSelf.frameHeight = 100;
                         CGFloat aa = animationView_A.frameX;
                         if (hasNextMonthDays) {
//                             animationView_A.frameY = -animationView_A.frameHeight + kVRGCalendarViewDayHeight+3;
                              animationView_A.frameX = -[UIScreen mainScreen].bounds.size.width;
                         } else {
//                             animationView_A.frameY = -animationView_A.frameHeight + 3;
                             animationView_A.frameX = -[UIScreen mainScreen].bounds.size.width;
                         }
//                         animationView_B.frameY = 0;
                         animationView_B.frameX = aa;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}

-(void)showPreviousMonth {
    if (isAnimating) return;
    isAnimating=YES;
    self.markedDates=nil;
    //Prepare current screen
    prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    BOOL hasPreviousDays = [currentMonth firstWeekDayInMonth]>1;
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //Prepare next screen
    self.currentMonth = [currentMonth offsetMonth:-1];
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:YES];
    prepAnimationPreviousMonth=NO;
    [self setNeedsDisplay];
    UIImage *imagePreviousMonth = [self drawCurrentState];
    
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    [animationHolder release];
    
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imagePreviousMonth];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasPreviousDays) {
//        animationView_B.frameY = animationView_A.frameY - (animationView_B.frameHeight-kVRGCalendarViewDayHeight) + 3;
        animationView_B.frameX = -[UIScreen mainScreen].bounds.size.width;
    } else {
//        animationView_B.frameY = animationView_A.frameY - animationView_B.frameHeight + 3;
        animationView_B.frameX = -[UIScreen mainScreen].bounds.size.width;
    }
    
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         CGFloat aa = animationView_A.frameX;
                         if (hasPreviousDays) {
//                             animationView_A.frameY = animationView_B.frameHeight-(kVRGCalendarViewDayHeight+3); 
                             animationView_A.frameX = [UIScreen mainScreen].bounds.size.width;
                         } else {
                             animationView_A.frameX = [UIScreen mainScreen].bounds.size.width;
//                              animationView_A.frameY = animationView_B.frameHeight-3;
                         }
                         animationView_B.frameX = aa;
//                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                     }
     ];
}


#pragma mark - update size & row count
-(void)updateSize {
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

-(float)calendarHeight {
    return kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
}

-(int)numRows
{
//    float lastBlock = [self.currentMonth numDaysInMonth]+([self.currentMonth firstWeekDayInMonth]-1);//monday is first day
    NSLog(@"%lu" , (unsigned long)[self.currentMonth numDaysInMonth]);
    NSLog(@"%lu" , (unsigned long)[self.currentMonth firstWeekDayInMonth]);
    float lastBlock;
    if ( [self.currentMonth firstWeekDayInMonth] == 7)
    {
         lastBlock = [self.currentMonth numDaysInMonth];
    }
    else
    {
         lastBlock = [self.currentMonth numDaysInMonth]+([self.currentMonth firstWeekDayInMonth]);
    }
    NSLog(@"%f" , ceilf(lastBlock/7));
    return ceilf(lastBlock/7);
}

#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    /*
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    self.selectedDate=nil;
    
    //Touch a specific day
    if (touchPoint.y > kVRGCalendarViewTopBarHeight)
    {
        float xLocation = touchPoint.x;
        float yLocation = touchPoint.y-kVRGCalendarViewTopBarHeight;
        
        int column = floorf(xLocation/(kVRGCalendarViewDayWidth+2));
        int row = floorf(yLocation/(kVRGCalendarViewDayHeight+2));
        
        int blockNr = (column+1)+row*7;
//        int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
        int firstWeekDay = [self.currentMonth firstWeekDayInMonth];
        int date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    }
    
    self.markedDates=nil;
    self.markedColors=nil;  
    
    CGRect rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-50, 0, 50, 40);
    
    //Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)) {
        [self showPreviousMonth];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)) {
        [self showNextMonth];
    } else if (CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoint)) {
        //Detect touch in current month
        int currentMonthIndex = [self.currentMonth month];
        int todayMonth = [[NSDate date] month];
        [self reset];
        if ((todayMonth!=currentMonthIndex) && [delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:[currentMonth month] targetHeight:self.calendarHeight animated:NO];
    }
     */
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
//    int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
    
    NSUInteger firstWeekDay = [self.currentMonth firstWeekDayInMonth];
    if (firstWeekDay == 7)
    {
        firstWeekDay = 0;
    }
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSDateFormatter *df_one = [[NSDateFormatter alloc] init];//格式化
    [df_one setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df_one setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"] ];
    NSDate *dateDD =[[NSDate alloc]init];
    dateDD =[df_one dateFromString:todayStr];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
                           NSDayCalendarUnit) fromDate:dateDD];
    NSDate * curr_date = [gregorian dateFromComponents:components];
    if ([curr_date isEqualToDate:self.currentMonth])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh"]];
        [formatter setDateFormat:@"YYYY年MM月dd日 EEEE"];
        NSString * str_XX = [[NSString alloc] initWithFormat:@"今天：%@" , [formatter stringFromDate:self.currentMonth]];
        labelCurrentMonth.text = str_XX;
         [str_XX release];
        [formatter release];
    }
   else
   {
       NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
       [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh"]];
       [formatter setDateFormat:@"YYYY年MM月"];
       NSString * str_XX = [[NSString alloc] initWithFormat:@"%@" , [formatter stringFromDate:self.currentMonth]];
       labelCurrentMonth.text = str_XX;
       [str_XX release];
       [formatter release];
   }
    labelCurrentMonth.font = [UIFont systemFontOfSize:12];
//    [labelCurrentMonth sizeToFit];
    labelCurrentMonth.frameX = roundf(self.frame.size.width/2 - labelCurrentMonth.frameWidth/2);
    labelCurrentMonth.frameY = 10;
    
    [currentMonth firstWeekDayInMonth];
    /*
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,kVRGCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);
    
    //Arrows
    int arrowSize = 12;
    int xmargin = 20;
    int ymargin = 18;
    
    //Arrow Left
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, xmargin+arrowSize/1.5, ymargin);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5,ymargin+arrowSize);
    CGContextAddLineToPoint(context,xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,xmargin+arrowSize/1.5, ymargin);
    
    CGContextSetFillColorWithColor(context, 
                                   [UIColor blackColor].CGColor);
    CGContextFillPath(context);
    
    //Arrow right
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    CGContextAddLineToPoint(context,self.frame.size.width-xmargin,ymargin+arrowSize/2);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5),ymargin+arrowSize);
    CGContextAddLineToPoint(context,self.frame.size.width-(xmargin+arrowSize/1.5), ymargin);
    
    CGContextSetFillColorWithColor(context, 
                                   [UIColor blackColor].CGColor);
    CGContextFillPath(context);
    */
    //Weekdays
    
    CGRect rectangle = CGRectMake(0,0 ,self.frame.size.width,kVRGCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [PublicMethod colorWithHexValue1:@"#F5F5F5"].CGColor);
    CGContextFillPath(context);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh"]];
    dateFormatter.dateFormat=@"EEE";
    //always assume gregorian with monday first
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
//    [weekdays moveObjectFromIndex:0 toIndex:6];
    
    CGContextSetFillColorWithColor(context, 
                                   [PublicMethod colorWithHexValue1:@"#666666"].CGColor);
    for (int i =0; i<[weekdays count]; i++)
    {
        NSString *weekdayValue1 = (NSString *)[weekdays objectAtIndex:i];
        NSString *weekdayValue = [weekdayValue1 substringFromIndex:1];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        [weekdayValue drawInRect:CGRectMake(i*(kVRGCalendarViewDayWidth+2), 40, kVRGCalendarViewDayWidth+2, 24) withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }
    
    int numRows = [self numRows];
    
    CGContextSetAllowsAntialiasing(context, NO);
    
    //Grid background
    float gridHeight = numRows*(kVRGCalendarViewDayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,kVRGCalendarViewTopBarHeight,self.frame.size.width,gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [PublicMethod colorWithHexValue1:@"#ffffff"].CGColor);
    //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xff0000"].CGColor);
    CGContextFillPath(context);
    
    
    //Grid white lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+1);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+1);
    
    for (int i = 1; i<7; i++)
    {
        /*
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight+gridHeight);
        */
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
    }
    
    CGContextStrokePath(context);
    
    //Grid dark lines
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:@"0xcfd4d8"].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight);
    for (int i = 1; i<7; i++)
    {
        //columns
        /*
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1, kVRGCalendarViewTopBarHeight+gridHeight);
        */
        if (i>numRows-1) continue;
        //rows
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1);
    }
    CGContextMoveToPoint(context, 0, gridHeight+kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, gridHeight+kVRGCalendarViewTopBarHeight);
    CGContextStrokePath(context);
    CGContextSetAllowsAntialiasing(context, YES);
    
    //Draw days
    CGContextSetFillColorWithColor(context, 
                                   [UIColor colorWithHexString:@"0x383838"].CGColor);
    
    
    //NSLog(@"currentMonth month = %i, first weekday in month = %i",[self.currentMonth month],[self.currentMonth firstWeekDayInMonth]);
    
    int numBlocks = numRows*7;
    NSDate *previousMonth = [self.currentMonth offsetMonth:-1];
    NSUInteger currentMonthNumDays = [currentMonth numDaysInMonth];
    NSUInteger prevMonthNumDays = [previousMonth numDaysInMonth];
    
    NSUInteger selectedDateBlock = ([selectedDate day]-1)+firstWeekDay;
    
    //prepAnimationPreviousMonth nog wat mee doen
    
    //prev next month
    BOOL isSelectedDatePreviousMonth = prepAnimationPreviousMonth;
    BOOL isSelectedDateNextMonth = prepAnimationNextMonth;
    
    if (self.selectedDate!=nil) {
        isSelectedDatePreviousMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]<[currentMonth month]) || [selectedDate year] < [currentMonth year];
        
        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]>[currentMonth month]) || [selectedDate year] > [currentMonth year];
        }
    }
    
    if (isSelectedDatePreviousMonth) {
        NSInteger lastPositionPreviousMonth = firstWeekDay-1;
        selectedDateBlock=lastPositionPreviousMonth-([selectedDate numDaysInMonth]-[selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [currentMonth numDaysInMonth] + (firstWeekDay-1) + [selectedDate day];
    }
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];//格式化
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"] ];
    NSDate *dateD =[[NSDate alloc]init];
    dateD =[df dateFromString:todayStr];
    NSInteger todayBlock = 0;
    
//    NSLog(@"currentMonth month = %i day = %i, todaydate day = %i",[currentMonth month],[currentMonth day],[todayDate month]);
    
    if ([dateD month] == [currentMonth month] && [dateD year] == [currentMonth year])
    {
        todayBlock = [dateD day] + firstWeekDay - 1;
    }
    NSLog(@"numBlocks = %d" , numBlocks);
    
    for (int i=0; i<numBlocks; i++)
    {
        NSInteger targetDate = i;
        int targetColumn = i%7;
        int targetRow = i/7;
        int targetX = targetColumn * (kVRGCalendarViewDayWidth+2);
        
        int targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2);
        
        // BOOL isCurrentMonth = NO;
        if (i<firstWeekDay)
        { //previous month
            targetDate = (prevMonthNumDays-firstWeekDay)+(i);
            NSString *hex = (isSelectedDatePreviousMonth) ? @"0x383838" : @"aaaaaa";
            
            CGContextSetFillColorWithColor(context, 
                                           [UIColor colorWithHexString:hex].CGColor);
        }
        else if (i>=(firstWeekDay+currentMonthNumDays))
        { //next month
            targetDate = (i) - (firstWeekDay+currentMonthNumDays);
            NSString *hex = (isSelectedDateNextMonth) ? @"0x383838" : @"aaaaaa";
            CGContextSetFillColorWithColor(context, 
                                           [UIColor colorWithHexString:hex].CGColor);
        }
        else
        { //current month
            // isCurrentMonth = YES;
            targetDate = (i-firstWeekDay)+1;
//            NSString *hex = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? @"0xaaaaaa" : @"0x383838";
            
            CGContextSetFillColorWithColor(context, 
                                           [PublicMethod colorWithHexValue1:@"#333333"].CGColor);
            NSString *date = [NSString stringWithFormat:@"%li",(long)targetDate];
            //draw selected date
            if (selectedDate && i==selectedDateBlock)
            {
                /*
                 //            CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                 //            CGContextAddRect(context, rectangleGrid);
                 //            CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x006dbc"].CGColor);
                 //            CGContextFillPath(context);
                 //            CGContextSetFillColorWithColor(context,
                 //                                           [UIColor whiteColor].CGColor);
                 CGRect rectangleGrid = CGRectMake(targetX+kVRGCalendarViewDayWidth/2+1,targetY,kVRGCalendarViewDayWidth/2+1,12+2);
                 CGContextSetFillColorWithColor(context,
                 [PublicMethod colorWithHexValue1:@"#FC5860"].CGColor);
                 UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:8];
                 //            NSString * todayStr = @"今天";
                 [@"今天" drawInRect:rectangleGrid withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentRight];
                 */
            }
            else if (i == firstWeekDay)
            {
                /*
                CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth/2+1,12+2);
                CGContextSetFillColorWithColor(context,
                                               [PublicMethod colorWithHexValue1:@"#333333"].CGColor);
                UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:10];
                int aa = [self.currentMonth month];
                NSString * todayStr1 = [[NSString alloc] initWithFormat:@"%d月", aa];
                [todayStr1 drawInRect:rectangleGrid withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
                CGContextSetFillColorWithColor(context,
                                               [PublicMethod colorWithHexValue1:@"#333333"].CGColor);
                 */
            }
            else if (todayBlock==i)
            {
                /*
                 CGRect rectangleGrid = CGRectMake(targetX,targetY,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
                 CGContextAddRect(context, rectangleGrid);
                 CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
                 CGContextFillPath(context);
                 
                 CGContextSetFillColorWithColor(context,
                 [UIColor whiteColor].CGColor);
                 */
                /*
                CGRect rectangleGrid = CGRectMake(targetX+kVRGCalendarViewDayWidth/2+1,targetY,kVRGCalendarViewDayWidth/2+1,12+2);
                CGContextSetFillColorWithColor(context,
                                               [PublicMethod colorWithHexValue1:@"#FC5860"].CGColor);
                UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:10];
                //            NSString * todayStr = @"今天";
                [@"今天" drawInRect:rectangleGrid withFont:font lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
                CGContextSetFillColorWithColor(context,
                                               [PublicMethod colorWithHexValue1:@"#333333"].CGColor);
                 */
                
                
            }
            [date drawInRect:CGRectMake(targetX+2, targetY+13, kVRGCalendarViewDayWidth, kVRGCalendarViewDayHeight) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:12] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        }
    }
    
    //    CGContextClosePath(context);
    
    
    //Draw markings
    if (!self.markedDates || isSelectedDatePreviousMonth || isSelectedDateNextMonth) return;
    
    for (int i = 0; i<[self.markedDates count]; i++)
    {
        id markedDateObj = [self.markedDates objectAtIndex:i];
        
        NSInteger targetDate;
        if ([markedDateObj isKindOfClass:[NSNumber class]]) {
            targetDate = [(NSNumber *)markedDateObj intValue];
        } else if ([markedDateObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)markedDateObj;
            targetDate = [date day];
        } else {
            continue;
        }
        
        NSString *date = [NSString stringWithFormat:@"%li",(long)targetDate];
    
        
        NSInteger targetBlock = firstWeekDay + (targetDate-1);
        NSInteger targetColumn = targetBlock%7;
        NSInteger targetRow = targetBlock/7;
        
        NSInteger targetX = targetColumn * (kVRGCalendarViewDayWidth+2);
        NSInteger targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2);
        CGRect rectangleGrid = CGRectMake(targetX+4,targetY,kVRGCalendarViewDayHeight+2,kVRGCalendarViewDayHeight+2);
//        CGContextAddRect(context, rectangleGrid);
//         CGContextAddArc(context, targetX+6+kVRGCalendarViewDayHeight/2, targetY+2+kVRGCalendarViewDayHeight/2, kVRGCalendarViewDayHeight/2, 0, M_PI*2, 1);
//        CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x006dbc"].CGColor);
//        CGContextFillPath(context);
        UIImage *  img = [UIImage imageNamed:@"111.png"];
        CGContextDrawImage(context, rectangleGrid, img.CGImage);
        CGContextSetFillColorWithColor(context,
                                      [PublicMethod colorWithHexValue1:@"#333333"].CGColor);
       
        [date drawInRect:CGRectMake(targetX+2, targetY+13, kVRGCalendarViewDayWidth, kVRGCalendarViewDayHeight) withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:12] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        
//        int targetX = targetColumn * (kVRGCalendarViewDayWidth+2) + 7;
//        int targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2) + 38;
        
//        CGRect rectangle = CGRectMake(targetX,targetY,32,2);//改变便签的长宽高
//        CGContextAddRect(context, rectangle);
      
//        UIColor *color;
//        if (selectedDate && selectedDateBlock==targetBlock) {
//            color = [UIColor whiteColor];
//        }  else if (todayBlock==targetBlock) {
//            color = [UIColor whiteColor];
//        } else {
//            color  = (UIColor *)[markedColors objectAtIndex:i];
//        }
//        
//        
//        CGContextSetFillColorWithColor(context, color.CGColor);
//        CGContextFillPath(context);
    }
}

#pragma mark - Draw image for animation
-(UIImage *)drawCurrentState
{
    float targetHeight = kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
    
    UIGraphicsBeginImageContext(CGSizeMake(kVRGCalendarViewWidth, targetHeight-kVRGCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -kVRGCalendarViewTopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark - Init
-(id)initDate:(NSString *)_strDate
{
    self = [super initWithFrame:CGRectMake(0, 0, kVRGCalendarViewWidth, 0)];
    if (self)
    {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds=YES;
        isAnimating=NO;
        self.labelCurrentMonth = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kVRGCalendarViewWidth, 13)];
        [self addSubview:labelCurrentMonth];
//        labelCurrentMonth.backgroundColor=[UIColor whiteColor];
        labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
        labelCurrentMonth.textColor = [UIColor colorWithHexString:@"0x666666"];
        labelCurrentMonth.textAlignment = UITextAlignmentCenter;
        labelCurrentMonth.backgroundColor = [UIColor clearColor];
        todayStr = _strDate;
        [self addSwif];
        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; //so delegate can be set after init and still get called on init
        //        [self reset];
    }
    return self;
}

-(void)addSwif
{
    UISwipeGestureRecognizer *recognizer;
    
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self addGestureRecognizer:recognizer];
    [recognizer release];
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self  addGestureRecognizer:recognizer];
    [recognizer release];
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [self addGestureRecognizer:recognizer];
    [recognizer release];
    
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self addGestureRecognizer:recognizer];
    [recognizer release];

}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer
{
    self.selectedDate=nil;
    /*
    if(recognizer.direction==UISwipeGestureRecognizerDirectionDown) {
        
        NSLog(@"swipe down");
        [self showPreviousMonth];
        //执行程序
    }
    if(recognizer.direction==UISwipeGestureRecognizerDirectionUp) {
        
        NSLog(@"swipe up");
        [self showNextMonth];
        //执行程序
    }
    
    */
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionLeft) {
        
        NSLog(@"swipe left");
          [self showNextMonth];
        //执行程序
    }
    
    
    
    if(recognizer.direction==UISwipeGestureRecognizerDirectionRight) {
        
        NSLog(@"swipe right");
        [self showPreviousMonth];
        //执行程序
    }
}

-(void)dealloc
{
    
    self.delegate=nil;
    self.currentMonth=nil;
    self.labelCurrentMonth=nil;
    
    self.markedDates=nil;
    self.markedColors=nil;
    
    [super dealloc];
}

@end
