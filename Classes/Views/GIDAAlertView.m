//
//  GIDASearchAlert.m 2011/10/28 to 2013/02/27
//  GIDAAlertView.m since 2013/02/27
//  TestAlert
//
//  Created by Alejandro Paredes on 10/28/11.
//
// Following methods are inspired in Yoshiki Vázquez Baeza work on previous versions
// of GIDAAlertView.
// - (id)initWithMessage:(NSString *)someMessage andAlertImage:(UIImage *)someImage;
// - (id) initWithSpinnerAndMessage:(NSString *)message;
// - (void)presentAlertFor:(float)seconds;
// - (void)presentAlertWithSpinnerAndHideAfterSelector:(SEL)selector from:(id)sender;
//

#import "GIDAAlertView.h"

@interface ProgressBar ()

@property (strong, nonatomic) UIColor *color;

@end
@implementation ProgressBar
- (void) drawRoundedRect:(CGRect)rect inContext:(CGContextRef)context withRadius:(CGFloat)radius{
	CGContextBeginPath (context);
    
	CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect),
    maxx = CGRectGetMaxX(rect);
    
	CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect),
    maxy = CGRectGetMaxY(rect);
    
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
}
-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        _color = nil;
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame andProgressBarColor:(UIColor *)pcolor {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        _color = pcolor;
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
	CGContextClearRect(context, rect);
	CGContextSetAllowsAntialiasing(context, true);
	CGContextSetLineWidth(context, 0.0);
	CGContextSetAlpha(context, 0.8);
	CGContextSetLineWidth(context, 2.0);
    if (!_color)
        _color = [UIColor redColor];

    UIColor *fillColor = _color;
    UIColor *borderColor = [UIColor clearColor];
	CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
	CGContextSetFillColorWithColor(context, [fillColor CGColor]);
    
	CGFloat backOffset = 2;
	CGRect backRect = CGRectMake(rect.origin.x + backOffset,
                                 rect.origin.y + backOffset,
                                 rect.size.width - backOffset*2,
                                 rect.size.height - backOffset*2);
    int radius = 8;
    if (rect.size.width < 21) {
        radius = rect.size.width/3;
    }
	[self drawRoundedRect:backRect inContext:context withRadius:radius];
	CGContextDrawPath(context, kCGPathFillStroke);
    
	CGRect clipRect = CGRectMake(backRect.origin.x + backOffset-1,
                                 backRect.origin.y + backOffset-1,
                                 backRect.size.width - (backOffset-1)*2,
                                 backRect.size.height - (backOffset-1)*2);
    
	[self drawRoundedRect:clipRect inContext:context withRadius:radius];
	CGContextClip (context);
    
	CGGradientRef glossGradient;
	CGColorSpaceRef rgbColorspace;
	size_t num_locations = 2;
	CGFloat locations[2] = { 0.0, 1.0 };
	CGFloat components[8] = { 1.0, 1.0, 1.0, 0.35, 1.0, 1.0, 1.0, 0.06 };
	rgbColorspace = CGColorSpaceCreateDeviceRGB();
	glossGradient = CGGradientCreateWithColorComponents(rgbColorspace,
                                                        components, locations, num_locations);
    
	CGRect ovalRect = CGRectMake(-130, -115, (rect.size.width*2),
                                 rect.size.width/2);
    
	CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
	CGPoint end = CGPointMake(rect.origin.x, rect.size.height/5);
    
	CGContextSetAlpha(context, 0.8);
	CGContextAddEllipseInRect(context, ovalRect);
	CGContextClip (context);
    
    CGContextDrawLinearGradient(context, glossGradient, start, end, 0);
    
	CGGradientRelease(glossGradient);
	CGColorSpaceRelease(rgbColorspace);
}
@end

@interface GIDAAlertView() {
    BOOL withSpinnerOrImage;
    float progress;
    NSTimer *timer;
    double timeSeconds;
    float _receivedDataBytes;
    float _totalFileSize;
    GIDAAlertViewType alertType;
    BOOL acceptedAlert;
    BOOL failedDownload;
}

@property (nonatomic, strong) UITextField   *textField;
@property (nonatomic, strong) UILabel       *theMessage;
@property (nonatomic, strong) UIColor       *alertColor;
@property (nonatomic, strong) NSTimer       *timer;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSURL         *userURL;
@property (nonatomic, strong) NSString      *mimeType;
@property (nonatomic, strong) NSString      *textEncoding;
@property (nonatomic, strong) ProgressBar   *progressBar;
@property (nonatomic, strong) UIColor   *progressBarColor;
@property (nonatomic, strong) UILabel       *progressLabel;

- (void) drawRoundedRect:(CGRect)rrect
               inContext:(CGContextRef)context
              withRadius:(CGFloat)radius;

@end

@implementation GIDAAlertView
@synthesize textField;
@synthesize theMessage;
@synthesize timer = _timer;

-(GIDAAlertViewType)type {
    return alertType;
}

-(id)initWithMessage:(NSString *)message andAlertImage:(UIImage *)image {
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        withSpinnerOrImage = YES;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [imageView setFrame:CGRectMake(100, 35, 80, 80)];
        [self addSubview:imageView];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        _responseData = nil;
        alertType = GIDAAlertViewMessageImage;
    }
    return  self;
}


-(id)initWithProgressBarAndMessage:(NSString *)message andTime:(NSInteger)seconds {
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        progress = -0.1;
        timeSeconds = seconds/10;
        withSpinnerOrImage = YES;
        //   UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Bar.png"]];
        //ProgressBar *iv = ;
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 0, 80)];
        // [iv setFrame:];
        [self addSubview:_progressBar];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        //[iv release];
        _responseData = nil;
        alertType = GIDAAlertViewProgressTime;
    }
    return  self;
}
-(void)moveProgress {
    if (progress <= 1.0) {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Bar.png"]];
        [iv setFrame:CGRectMake(100, 35, 8+progress*80, 80)];
        [self addSubview:iv];
        progress += 0.1;
        // [progressView setProgress:progress];
    } else {
        [_timer invalidate];
        _timer = nil;
        [self dismissWithClickedButtonIndex:0 animated:NO];
    }
}
-(void)presentProgressBar {
    [self show];
    _timer = [NSTimer timerWithTimeInterval:timeSeconds target:self selector:@selector(moveProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

-(id) initWithSpinnerAndMessage:(NSString *)message {
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        withSpinnerOrImage = YES;
        UIActivityIndicatorView *theSpinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [theSpinner setFrame:CGRectMake(100, 35, 80, 80)];
        
        [theSpinner startAnimating];
        [self addSubview:theSpinner];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        _responseData = nil;
        alertType = GIDAAlertViewSpinner;
    }
    return self;
}
- (id)initWithPrompt:(NSString *)prompt cancelButtonTitle:(NSString *)cancelTitle acceptButtonTitle:(NSString *)acceptTitle {
    while ([prompt sizeWithFont:[UIFont systemFontOfSize:18.0]].width > 240.0) {
        prompt = [NSString stringWithFormat:@"%@...", [prompt substringToIndex:[prompt length] - 4]];
    }
    
    if (self = [super initWithTitle:prompt message:@"\n" delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:acceptTitle, nil]) {
        withSpinnerOrImage = NO;
        UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 31.0)];
        [theTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [theTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [theTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [theTextField setTextAlignment:NSTextAlignmentCenter];
        [theTextField setKeyboardAppearance:UIKeyboardAppearanceAlert];
        [self addSubview:theTextField];
        self.textField = theTextField;
        
        _alertColor = [UIColor blackColor];
        
        // if not >= 4.0
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
        if (![sysVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedDescending) {
            CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 130.0);
            [self setTransform:translate];
        }
        _responseData = nil;
        alertType = GIDAAlertViewPrompt;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image andPrompt:(NSString *)prompt cancelButtonTitle:(NSString *)cancelTitle acceptButtonTitle:(NSString *)acceptTitle {
    while ([prompt sizeWithFont:[UIFont systemFontOfSize:18.0]].width > 240.0) {
        prompt = [NSString stringWithFormat:@"%@...", [prompt substringToIndex:[prompt length] - 4]];
    }
    NSString *height = @"\n";
    for (int i = 0; i < image.size.height; i+=14) {
        height = [height stringByAppendingString:@"\n"];
    }
    if (self = [super initWithTitle:prompt message:height delegate:nil cancelButtonTitle:cancelTitle otherButtonTitles:acceptTitle, nil]) {
        withSpinnerOrImage = NO;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGSize imageSize = image.size;
        CGRect imageViewFrame = CGRectMake((280-imageSize.width)/2, 20.0f, imageSize.width, imageSize.height);
        [imageView setFrame:imageViewFrame];
        UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, imageSize.height+40.0, 260.0, 31.0)];
        [theTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [theTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [theTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [theTextField setTextAlignment:NSTextAlignmentCenter];
        [theTextField setKeyboardAppearance:UIKeyboardAppearanceAlert];
        [self addSubview:imageView];
        [self addSubview:theTextField];
        self.textField = theTextField;
        
        _alertColor = [UIColor blackColor];
        
        // if not >= 4.0
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
        if (![sysVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedDescending) {
            CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 130.0);
            [self setTransform:translate];
        }
        _responseData = nil;
        alertType = GIDAAlertViewPrompt;
    }
    return self;
}
-(id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelTitle acceptButtonTitle:(NSString *)acceptTitle andMessage:(NSString *)message {
    while ([title sizeWithFont:[UIFont systemFontOfSize:18.0]].width > 240.0) {
        title = [NSString stringWithFormat:@"%@...", [title substringToIndex:[title length] - 4]];
    }
    
    if (self = [super initWithTitle:title message:@"\n" delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:acceptTitle, nil]) {
        withSpinnerOrImage = NO;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 31.0)];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setText:message];
        [self addSubview:label];
        theMessage = label;
        
        _alertColor = [UIColor blackColor];
        
        // if not >= 4.0
        NSString *sysVersion = [[UIDevice currentDevice] systemVersion];
        if (![sysVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedDescending) {
            CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 130.0);
            [self setTransform:translate];
        }
        _responseData = nil;
        alertType = GIDAAlertViewNoPrompt;
    }
    return self;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _totalFileSize = response.expectedContentLength;
    _responseData = [[NSMutableData alloc] init];
    _mimeType = [response MIMEType];
    _textEncoding = [response textEncodingName];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    _receivedDataBytes += [data length];
    progress = _receivedDataBytes / (float)_totalFileSize;
    [_responseData appendData:data];
    
    [_progressBar removeFromSuperview];
    
    if (progress < 1 && progress >= 0) {
        NSString *string = [NSString stringWithFormat:@"%.1f%@",progress*100,@"%"];
        [_progressLabel setText:string];
        if (_progressBarColor) {
            _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+progress*80, 80) andProgressBarColor:_progressBarColor];
        } else {
            _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+progress*80, 80)];
        }
    } else {
        if (_progressBarColor) {
            _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+80, 80) andProgressBarColor:_progressBarColor];
        } else {
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+80, 80)];
        }
        [_progressLabel setText:@"100%"];
    }
    [self addSubview:_progressBar];
    [self bringSubviewToFront:_progressLabel];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [_progressBar removeFromSuperview];
    if (_progressBarColor) {
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+80, 80) andProgressBarColor:_progressBarColor];
    } else {
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 8+80, 80)];
    }
    
    [_progressLabel setText:@"100%"];
    
    [self addSubview:_progressBar];
    
    [self bringSubviewToFront:_progressLabel];
    double delayInSeconds = 0.7;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self dismissWithClickedButtonIndex:0 animated:NO];
    });
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@",[error description]);
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _responseData = nil;
        failedDownload = YES;
        [self dismissWithClickedButtonIndex:0 animated:NO];
    });
}

- (id)initWithProgressBarAndMessage:(NSString *)message andURL:(NSURL *)url andProgressBarColor:(UIColor *)pcolor {
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        _receivedDataBytes = 0;
        _totalFileSize = 0;
        progress = -0.1;
        withSpinnerOrImage = YES;
        _progressBarColor = pcolor;
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 0, 80) andProgressBarColor:pcolor];
        [self addSubview:_progressBar];
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(115, 50, 60, 50)];
        [_progressLabel setTextAlignment:NSTextAlignmentCenter];
        _progressLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [_progressLabel setTextColor:[UIColor whiteColor]];
        [_progressLabel setBackgroundColor:[UIColor clearColor]];
        [_progressLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [self addSubview:_progressLabel];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        failedDownload = NO;
        _responseData = nil;
        //[iv release];
        _userURL = url;
        alertType = GIDAAlertViewProgressURL;
    }
    return  self;
}
- (id)initWithProgressBarAndMessage:(NSString *)message andURL:(NSURL *)url {
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        _receivedDataBytes = 0;
        _totalFileSize = 0;
        progress = -0.1;
        withSpinnerOrImage = YES;
        _progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(100, 35, 0, 80)];
        [self addSubview:_progressBar];
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(115, 50, 60, 50)];
        [_progressLabel setTextAlignment:NSTextAlignmentCenter];
        _progressLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [_progressLabel setTextColor:[UIColor whiteColor]];
        [_progressLabel setBackgroundColor:[UIColor clearColor]];
        [_progressLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [self addSubview:_progressLabel];
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        failedDownload = NO;
        _responseData = nil;
        //[iv release];
        _userURL = url;
        alertType = GIDAAlertViewProgressURL;
    }
    return  self;
}


- (void)setColor:(UIColor *)color {
    _alertColor = color;
}

- (void)show {
    [textField becomeFirstResponder];
    [super show];
}

- (NSString *)enteredText {
    return textField.text;
}
- (NSString *)message {
    return [[self theMessage] text];
}


- (void) layoutSubviews {
	for (UIView *sub in [self subviews])
	{
		if([sub class] == [UIImageView class] && sub.tag == 0)
		{
			[sub removeFromSuperview];
			break;
		}
	}
}

- (void)drawRect:(CGRect)rect
{
    if (withSpinnerOrImage) {
        rect.origin.x = (rect.size.width - 180)/2;
        rect.size.width = rect.size.height = 180;
    }
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	CGContextClearRect(context, rect);
	CGContextSetAllowsAntialiasing(context, true);
	CGContextSetLineWidth(context, 0.0);
	CGContextSetAlpha(context, 0.8);
	CGContextSetLineWidth(context, 2.0);
    UIColor *fillColor = _alertColor;
    UIColor *borderColor = nil;
    if (withSpinnerOrImage) {
        borderColor = [UIColor clearColor];
    } else {
        borderColor = [UIColor colorWithHue:0.625 saturation:0.0 brightness:0.8 alpha:0.8];
    }
    
	CGContextSetStrokeColorWithColor(context, [borderColor CGColor]);
	CGContextSetFillColorWithColor(context, [fillColor CGColor]);
    
	CGFloat backOffset = 2;
	CGRect backRect = CGRectMake(rect.origin.x + backOffset,
                                 rect.origin.y + backOffset,
                                 rect.size.width - backOffset*2,
                                 rect.size.height - backOffset*2);
    
	[self drawRoundedRect:backRect inContext:context withRadius:8];
	CGContextDrawPath(context, kCGPathFillStroke);
    
	CGRect clipRect = CGRectMake(backRect.origin.x + backOffset-1,
                                 backRect.origin.y + backOffset-1,
                                 backRect.size.width - (backOffset-1)*2,
                                 backRect.size.height - (backOffset-1)*2);
    
	[self drawRoundedRect:clipRect inContext:context withRadius:8];
	CGContextClip (context);
    
	CGGradientRef glossGradient;
	CGColorSpaceRef rgbColorspace;
	size_t num_locations = 2;
	CGFloat locations[2] = { 0.0, 1.0 };
	CGFloat components[8] = { 1.0, 1.0, 1.0, 0.35, 1.0, 1.0, 1.0, 0.06 };
	rgbColorspace = CGColorSpaceCreateDeviceRGB();
	glossGradient = CGGradientCreateWithColorComponents(rgbColorspace,
                                                        components, locations, num_locations);
    
	CGRect ovalRect = CGRectMake(-130, -115, (rect.size.width*2),
                                 rect.size.width/2);
    
	CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
	CGPoint end = CGPointMake(rect.origin.x, rect.size.height/5);
    
	CGContextSetAlpha(context, 0.8);
	CGContextAddEllipseInRect(context, ovalRect);
	CGContextClip (context);
    if (!withSpinnerOrImage) {
        CGContextDrawLinearGradient(context, glossGradient, start, end, 0);
    }
    
	CGGradientRelease(glossGradient);
	CGColorSpaceRelease(rgbColorspace);
}

- (void) drawRoundedRect:(CGRect) rect inContext:(CGContextRef) context
              withRadius:(CGFloat) radius
{
	CGContextBeginPath (context);
    
	CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect),
    maxx = CGRectGetMaxX(rect);
    
	CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect),
    maxy = CGRectGetMaxY(rect);
    
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
}
-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}
-(void)setDelegate:(id)delegate {
    [super setDelegate:self];
    _gavdelegate = delegate;
}
-(void)presentAlertWithSpinnerAndHideAfterSelector:(SEL)selector from:(id)sender withObject:(id)object {
    [self show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [sender performSelector:selector withObject:object];
#pragma clang diagnostic pop
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [self dismissWithClickedButtonIndex:0 animated:YES];
                       });
    });
}
-(id)initWithCharacter:(NSString *)character andMessage:(NSString *)message{
    self = [super initWithTitle:@"\n\n\n\n\n" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    if (self) {
        withSpinnerOrImage = YES;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 35, 100, 80)];
        [label setText:character];
        [label setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:80]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:UITextAlignmentCenter];
        [label setBackgroundColor:[UIColor clearColor]];
        [self addSubview:label];
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 115, 160, 50)];
        [messageLabel setTextAlignment:NSTextAlignmentCenter];
        [messageLabel setText:message];
        [messageLabel setBackgroundColor:[UIColor clearColor]];
        [messageLabel setTextColor:[UIColor whiteColor]];
        [messageLabel setFont:[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:20]];
        [messageLabel setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:messageLabel];
        _responseData = nil;
    }
    return self;
}
-(id)initWithCheckMarkAndMessage:(NSString *)message {
    self = [self initWithCharacter:[NSString stringWithCString:"\u2714" encoding:NSUTF8StringEncoding] andMessage:message];
    if (self) {
        alertType = GIDAAlertViewCheck;
    }
    return self;
}
-(id)initWithXMarkAndMessage:(NSString *)message {
    self = [self initWithCharacter:@"\u2718" andMessage:message];
    if (self) {
        alertType = GIDAAlertViewCheck;
    }
    return self;
}
-(void)presentAlertFor:(float)seconds {
    [self show];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self dismissWithClickedButtonIndex:0 animated:YES];
    });
}

-(NSDictionary *)getDownloadedData {
    NSDictionary *dictionary;
    if (failedDownload) {
        dictionary = nil;
    } else {
        dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                      _responseData, @"data",
                      _userURL,      @"url",
                      _mimeType,     @"mime",
                      _textEncoding, @"encoding",
                      nil];
    }
    return dictionary;
}
-(void)progresBarStartDownload {
    [self show];
    NSURLRequest *request = [NSURLRequest requestWithURL:_userURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20.0];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        acceptedAlert = YES;
    } else {
        acceptedAlert = NO;
    }
    if ([_gavdelegate respondsToSelector:@selector(alertOnClicked:)])
        [_gavdelegate alertOnClicked:(GIDAAlertView *)alertView];
}
-(BOOL)accepted {
    return acceptedAlert;
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        acceptedAlert = YES;
    } else {
        acceptedAlert = NO;
    }
    if([_gavdelegate respondsToSelector:@selector(alertOnDismiss:)])
        [_gavdelegate alertOnDismiss:(GIDAAlertView *)alertView];
    if ([_gavdelegate respondsToSelector:@selector(alertFinished:)])
        [_gavdelegate alertFinished:(GIDAAlertView *)alertView];
}
@end
