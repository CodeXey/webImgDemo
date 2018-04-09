//
//  ViewController.m
//  webImg
//
//  Created by 白苇杭 on 2018/4/8.
//  Copyright © 2018年 iosdio. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <XLPhotoBrowser+CoderXL/XLPhotoBrowser.h>

@interface ViewController ()<WKNavigationDelegate, UIScrollViewDelegate>

@property (nonatomic, strong)WKWebView *webView;
@property (nonatomic, strong)UILabel *bottomLbl;
@property (nonatomic, copy)NSArray *imgsArr;

@end

@implementation ViewController {
    CGFloat _scrollHeight;
    NSString *_kPageURL;
}

-(NSArray *)imgsArr {
    if (!_imgsArr) {
        _imgsArr = [NSArray array];
    }
    return _imgsArr;
}

-(WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
        _webView.navigationDelegate = self;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_webView];
    }
    return _webView;
}

-(UILabel *)bottomLbl {
    if (!_bottomLbl) {
        _bottomLbl = ({
            UILabel *label = [[UILabel alloc] init];
            label.font = [UIFont boldSystemFontOfSize:20];
            label.textAlignment = NSTextAlignmentCenter;
            label.frame = CGRectMake(0, self.view.bounds.size.height - 30, self.view.bounds.size.width, 30);
            label.text = @"点击图片看看";
            label.backgroundColor = [UIColor whiteColor];
            label;
        });
        [self.view addSubview:_bottomLbl];
        [self.view bringSubviewToFront:_bottomLbl];
    }
    return _bottomLbl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _kPageURL = @"https://tech.meituan.com/DiveIntoCategory.html";
    [self loadContainerURL:_kPageURL];
    self.webView.scrollView.delegate = self;
    self.bottomLbl.transform  = CGAffineTransformMakeTranslation(0, 100);
}


-(void)loadContainerURL:(NSString *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    [self.webView loadRequest:request];
}

#pragma mark --- webNavDelegate
//webImage缩放,样式表图片是100%，无法全部显示
-(void)setWebImgsScaleZoom {
    NSString *script = [NSString stringWithFormat:
                        @"var script = document.createElement('script');"
                        "script.type = 'text/javascript';"
                        "script.text = \"function ResizeImages() { "
                        "var img;"
                        "var maxwidth=%f;"
                        "for(i=0;i <document.images.length;i++){"
                        "img = document.images[i];"
                        "if(img.width > maxwidth){"
                        "img.width = maxwidth;"
                        "}"
                        "}"
                        "}\";"
                        "document.getElementsByTagName('head')[0].appendChild(script);",self.view.bounds.size.width - 20];
    [self.webView evaluateJavaScript:script completionHandler:nil];
    [self.webView evaluateJavaScript:@"ResizeImages();" completionHandler:nil];
}

-(void)getWebImgInfos {
    NSString *getWebImgUrls = @"\
    function getImgUrls() {\
    var imgs = document.getElementsByTagName('img');\
    var urls = [];\
    for (var i = 0; i < imgs.length; i++) {\
    var img = imgs[i];\
    urls[i] = img.src;\
    }\
    return urls;\
    }";
    [self.webView evaluateJavaScript:getWebImgUrls completionHandler:nil];
    [self.webView evaluateJavaScript:@"getImgUrls()" completionHandler:^(NSArray *imgs, NSError * _Nullable error) {
        self.imgsArr = imgs;
    }];
}

//添加图片点击事件
-(void)addWebImgsCliclMethod {
    NSString *imgClickJS = @"function imgClickAction(){var imgs=document.getElementsByTagName('img');var length=imgs.length;for(var i=0; i < length;i++){img=imgs[i];if(\"ad\" ==img.getAttribute(\"flag\")){var parent = this.parentNode;if(parent.nodeName.toLowerCase() != \"a\")return;}img.onclick=function(){window.location.href=this.src}}}";
    [self.webView evaluateJavaScript:imgClickJS completionHandler:nil];
    [self.webView evaluateJavaScript:@"imgClickAction()" completionHandler:nil];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self setWebImgsScaleZoom];
    [self getWebImgInfos];
    [self addWebImgsCliclMethod];
    [webView evaluateJavaScript:@"Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight)"
              completionHandler:^(id _Nullable result, NSError * _Nullable error){
                  if (!error) {
                      NSNumber *height = result;
                      _scrollHeight = [height intValue];
                  }
              }];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *shouldHandleString = navigationAction.request.URL.absoluteString;
    
    if ([self.imgsArr containsObject:shouldHandleString]) {
        NSInteger index = [self.imgsArr indexOfObject:shouldHandleString];
        [XLPhotoBrowser showPhotoBrowserWithImages:self.imgsArr currentImageIndex:index].browserStyle = XLPhotoBrowserStyleSimple;
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int scrollPos = scrollView.contentOffset.y;
    (scrollPos < 100) ? [self dismissLbl] : [self showLabel];
}

-(void)showLabel {
    [UIView animateWithDuration:.3 animations:^{
        self.bottomLbl.transform = CGAffineTransformIdentity;
    }];
}

-(void)dismissLbl {
    [UIView animateWithDuration:.3 animations:^{
        self.bottomLbl.transform  = CGAffineTransformMakeTranslation(0, 100);
    }];
}

@end
