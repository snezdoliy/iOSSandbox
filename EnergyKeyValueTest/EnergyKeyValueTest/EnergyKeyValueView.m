//
//  EnergyKeyValueView.m
//  
//
//  Created by Sergii Nezdolii on 27/11/15.
//
//

#import "EnergyKeyValueView.h"

#define DEG_TO_RAD(angle) ((angle) / 180.0 * M_PI)
#define RAD_TO_DEG(radians) ((radians) * (180.0 / M_PI))
#define START -180.0f
static CGFloat const kMarkerWidth = 0.002f;
static CGFloat const kLeftMarkerAngle = 45.0f;
static CGFloat const kRightMarkerAngle = 135.0f;


@interface EnergyKeyValueView() {
    BOOL rendered, animationInProgress;
}

@property (strong, nonatomic) CAShapeLayer *emptyMeter;
@property (strong, nonatomic) CAShapeLayer *valueMeter;
@property (strong, nonatomic) NSMutableArray *staticLayers;
@property (strong, nonatomic) NSMutableArray *dynamicLayers;

@end

@implementation EnergyKeyValueView

#pragma mark - Basic UIView setup

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    //Do whatever is needed to be done for common init
    self.staticLayers = [NSMutableArray new];
    self.dynamicLayers = [NSMutableArray new];
    self.clipsToBounds = YES;
}

- (void)prepareForInterfaceBuilder {
    [self commonInit];
    [self updateWithAvg:@0 value:@0 animated:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!rendered) {
        [self drawBasedOnLayers];
        rendered = YES;
    }
#if TARGET_INTERFACE_BUILDER
    [self updateWithAvg:@10 value:@8 animated:NO];
#endif
}

- (void)updateWithAvg:(NSNumber *)avg value:(NSNumber *)value animated:(BOOL)animated {
    CGFloat valueOffset = avg.floatValue == 0 ? 0 : MIN(M_PI, M_PI_2 * value.floatValue / avg.floatValue);
    if (animated) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.fromValue = @(0);
        animation.toValue = @(valueOffset);
        animation.duration = 1.0f * valueOffset / M_PI;
        animation.repeatCount = 1;
        //This allows to not roll animation back when done
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [self.valueMeter addAnimation:animation forKey:@"ValueUpdateAnimation"];
    } else {
        [self.valueMeter setValue:@(valueOffset) forKeyPath:@"transform.rotation"];
    }
}

- (void)drawBasedOnLayers {
    [self drawStaticLayers];
    [self drawDynamicLayers];
}

#pragma mark - Calculation Helpers

- (CGPoint)getCenter {
    CGRect myFrame = self.bounds;
    
    return CGPointMake(CGRectGetMidX(myFrame), CGRectGetMaxY(myFrame));
}

- (CGFloat)getRadius {
    CGRect myFrame = self.bounds;
    
    return MAX(CGRectGetWidth(myFrame), CGRectGetHeight(myFrame))/2.0f;
}

- (CGRect)getOvalRectForMeterWidth:(CGFloat)meterwidth {
    
    CGRect ovalFrame = CGRectInset(self.bounds, meterwidth/2.0f, meterwidth/2.0f);
    ovalFrame.size.height *= 2;
    ovalFrame.size.height += meterwidth;

    return ovalFrame;
}

#pragma mark - Drawing methods

- (void)drawStaticLayers {
    CAShapeLayer *shadowLayer = [self createCircleLayerWithCenter:[self getCenter] radius:[self getRadius]-1 width:self.meterWidth color:self.shadowColor];
    shadowLayer.frame = CGRectOffset(shadowLayer.frame, 0, 1);
    
    self.emptyMeter = [self createCircleLayerWithCenter:[self getCenter] radius:[self getRadius] width:self.meterWidth color:self.emptyColor];
    CAShapeLayer *leftMarker = [self createMarkerLayerWithCenter:[self getCenter]
                                                          radius:[self getRadius]
                                                           width:self.meterWidth
                                                           color:self.markerColor
                                                  angleInDegrees:kLeftMarkerAngle];

    CAShapeLayer *rightMarker = [self createMarkerLayerWithCenter:[self getCenter]
                                                           radius:[self getRadius]
                                                            width:self.meterWidth
                                                            color:self.markerColor
                                                   angleInDegrees:kRightMarkerAngle];
    
    for (CALayer *layer in self.staticLayers) {
        [layer removeFromSuperlayer];
    }
    [self.staticLayers removeAllObjects];
    [self.staticLayers addObjectsFromArray:@[shadowLayer, self.emptyMeter, leftMarker, rightMarker]];
    //TODO: convert to ObjectiveSugar syntax
    for (CALayer *layer in self.staticLayers) {
        [self.layer addSublayer:layer];
    }
}

- (void)drawDynamicLayers {
    self.valueMeter = [self createCircleLayerWithCenter:[self getCenter]
                                                 radius:[self getRadius]
                                                  width:self.meterWidth
                                                  color:self.fillColor
                                         angleInDegrees:180.0f];
    self.valueMeter.strokeEnd = 0.5f;
    for (CALayer *layer in self.dynamicLayers) {
        [layer removeFromSuperlayer];
    }
    [self.dynamicLayers removeAllObjects];
    [self.dynamicLayers addObjectsFromArray:@[self.valueMeter]];
    //TODO: convert to ObjectiveSugar syntax
    for (CALayer *layer in self.dynamicLayers) {
        [self.layer addSublayer:layer];
    }
    
}

#pragma mark - Drawing private methods - helpers

- (CAShapeLayer *) createCircleLayerWithCenter:(CGPoint)center radius:(CGFloat)radius width:(CGFloat)width color:(UIColor *)color  {
    CAShapeLayer *circle = [self createCircleLayerWithCenter:center
                                                      radius:radius
                                                       width:width
                                                       color:color
                                              angleInDegrees:0.0f];
    
    return circle;
}

- (CAShapeLayer *)createMarkerLayerWithCenter:(CGPoint)center radius:(CGFloat)radius width:(CGFloat)width color:(UIColor *)color angleInDegrees:(CGFloat)angleInDegrees {

    CAShapeLayer *marker = [self createCircleLayerWithCenter:center
                                                      radius:radius
                                                       width:width
                                                       color:color
                                              angleInDegrees:angleInDegrees];
    marker.strokeStart = 0.0f;
    marker.strokeEnd = kMarkerWidth;

    return marker;
}

- (CAShapeLayer *)createCircleLayerWithCenter:(CGPoint)center radius:(CGFloat)radius width:(CGFloat)width color:(UIColor *)color angleInDegrees:(CGFloat)angleInDegrees {
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.frame = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2);
    [circle setValue:@(DEG_TO_RAD(START+angleInDegrees)) forKeyPath:@"transform.rotation"];
    circle.fillColor = nil;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = width;
    
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:[self getOvalRectForMeterWidth:width]];
    circle.path = circlePath.CGPath;
    circle.bounds = CGPathGetBoundingBox(circlePath.CGPath);
    
    return circle;
}

@end
