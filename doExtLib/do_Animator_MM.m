//
//  do_Animator_MM.m
//  DoExt_MM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "do_Animator_MM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doIPage.h"
#import "doUIModuleHelper.h"
#import "doJsonHelper.h"

@interface AnimatePoint : NSObject

@property (nonatomic, strong) NSString *curve;
@property (nonatomic, assign) float duration;
@property (nonatomic, strong) NSDictionary *propertys;

@end

@implementation AnimatePoint
@synthesize curve,duration,propertys;
@end

@implementation do_Animator_MM
{
    NSMutableArray *_points;
}

#pragma mark - 注册属性（--属性定义--）
/*
 [self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];
    //注册属性
    _points = [NSMutableArray array];
}

//销毁所有的全局对象
-(void)Dispose
{
    //(self)类销毁时会调用递归调用该方法，在该类中主动生成的非原生的扩展对象需要主动调该方法使其销毁
    [_points removeAllObjects];
    _points = nil;
}
#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)append:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    
    AnimatePoint *point = [AnimatePoint new];
    point.curve = [_dictParas objectForKey:@"curve"];
    point.duration = [[_dictParas objectForKey:@"duration"] floatValue];
    if ([_dictParas objectForKey:@"props"]) {
        point.propertys = [_dictParas objectForKey:@"props"];
    }
    [_points addObject:point];
}

-(void) SetAnimation:(doUIModule *) _comp :(NSString*) _callbackName
{
    if(_comp==nil||_comp.CurrentUIModuleView==nil) return;
    doUIModule *animationUI = _comp;
    __block UIView *_view =  (UIView*)_comp.CurrentUIModuleView;
    
    NSInteger count = _points.count;
    CGFloat totalTime = 0;
    int i=0;
    for (; i<count; i++) {
        AnimatePoint *point = (AnimatePoint *)[_points objectAtIndex:i];
        totalTime += point.duration/1000;
    }
    
    void (^animationBlock)() = ^{
        NSInteger i = 0;
        CGFloat delay = 0;
        CGFloat duration = 0;
        
        CGFloat height,width,x,y,alpha;
        height = CGRectGetHeight(_view.frame);
        width = CGRectGetWidth(_view.frame);
        x = CGRectGetMinX(_view.frame);
        y = CGRectGetMinY(_view.frame);
        alpha = _view.alpha;
        NSString *bgColor = @"";

        for (; i<count; i++) {
            AnimatePoint *point = (AnimatePoint *)[_points objectAtIndex:i];
            NSString *curve = point.curve;
            duration = point.duration/1000;
            

            if (point.propertys) {
                if ([point.propertys objectForKey:@"bgColor"]) {
                    bgColor = [point.propertys objectForKey:@"bgColor"];
                }
                if ([point.propertys objectForKey:@"height"]) {
                    height = [[point.propertys objectForKey:@"height"] floatValue]*animationUI.YZoom;
                }
                if ([point.propertys objectForKey:@"width"]) {
                    width = [[point.propertys objectForKey:@"width"] floatValue]*animationUI.XZoom;
                }
                if ([point.propertys objectForKey:@"x"]) {
                    x = [[point.propertys objectForKey:@"x"] floatValue]*animationUI.XZoom;
                }
                if ([point.propertys objectForKey:@"y"]) {
                    y = [[point.propertys objectForKey:@"y"] floatValue]*animationUI.YZoom;
                }
                if ([point.propertys objectForKey:@"alpha"]) {
                    alpha = [[point.propertys objectForKey:@"alpha"] floatValue];
                }
            }
            
            UIViewAnimationCurve opertion ;
            if ([curve isEqualToString:@"EaseInOut"]) {
                opertion = UIViewAnimationCurveEaseInOut;
            }else if ([curve isEqualToString:@"EaseIn"]){
                opertion = UIViewAnimationCurveEaseIn;
            }else if ([curve isEqualToString:@"EaseOut"]){
                opertion = UIViewAnimationCurveEaseOut;
            }else
                opertion = UIViewAnimationCurveLinear;
            /*
             iOS不支持设置多个curve,现设置默认值为UIViewAnimationCurveEaseOut
             setAnimationCurve 为UIView全局设置，因此只有最后一次设置是有效的
             */
//            opertion = UIViewAnimationCurveEaseOut;
            
            float startTime = delay/totalTime;
            float duration1 = duration/totalTime;


            [UIView addKeyframeWithRelativeStartTime:startTime relativeDuration:duration1 animations:^{
                [UIView setAnimationCurve:opertion];
                if (point.propertys) {
                    if (bgColor.length > 0) {
                        [_view.layer setBackgroundColor:[doUIModuleHelper GetColorFromString:bgColor :_view.backgroundColor].CGColor];
                    }
                    _view.alpha = alpha;
                    CGRect r = CGRectMake(x, y, width, height);
                    if (![NSStringFromCGRect(_view.frame) isEqualToString:NSStringFromCGRect(r)]) {
                        _view.frame = r;
                    }
                }
            }];
            delay += duration;
        }
        //改变属性值
        [animationUI SetPropertyValue:@"x" :[@((int)(x/animationUI.XZoom)) stringValue]];
        [animationUI SetPropertyValue:@"y" :[@((int)(y/animationUI.YZoom)) stringValue]];
        [animationUI SetPropertyValue:@"width" :[@((int)(width/animationUI.XZoom)) stringValue]];
        [animationUI SetPropertyValue:@"height" :[@((int)(height/animationUI.YZoom)) stringValue]];
        if (bgColor.length>0) {
            [animationUI SetPropertyValue:@"bgColor" :bgColor];
        }
        [doUIModuleHelper generateBorder:animationUI :[animationUI GetPropertyValue:@"border"]];
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateKeyframesWithDuration:totalTime delay:0 options:0 animations:animationBlock completion:^(BOOL finished) {
//            [doUIModuleHelper OnRedraw:animationUI];

            [animationUI.CurrentPage.ScriptEngine Callback:_callbackName :nil];
        }];
    });
}
-(void)LoadModelFromString:(NSString *)_moduleText
{
    id _rootJsonValue =[doJsonHelper LoadDataFromText : _moduleText];
    if ([_rootJsonValue isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dict in _rootJsonValue) {
            [self append:@[dict]];
        }
    }else
        [self append:@[_rootJsonValue]];

}

@end