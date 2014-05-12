#import "IOSiAP.h"
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

//******************************************************************************
// class iAPProductsRequestDelegate
//******************************************************************************
#pragma mark - class iAPProductsRequestDelegate

// OC不能直接把委托设置为C++的this,因此声明了这个委托，然后可以将委托设为该类的对象
@interface iAPProductsRequestDelegate : NSObject<SKProductsRequestDelegate>
@property (nonatomic, assign) IOSiAP *iosiap;
@end

@implementation iAPProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"-----------收到产品反馈信息--------------");
    NSLog(@"invalidProductIdentifiers Product ID:%@",response.invalidProductIdentifiers);
    // release old
    if (_iosiap->skProducts) {
        [(NSArray *)(_iosiap->skProducts) release];
    }
    
    // record new product
    _iosiap->skProducts = [response.products retain];
    
    for (int index = 0; index < [response.products count]; index++) {
        SKProduct *skProduct = [response.products objectAtIndex:index];
        
        // check is valid
        bool isValid = true;
        for (NSString *invalidIdentifier in response.invalidProductIdentifiers) {
            NSLog(@"invalidIdentifier:%@", invalidIdentifier);
            if ([skProduct.productIdentifier isEqualToString:invalidIdentifier]) {
                isValid = false;
                break;
            }
        }
        
        NSLog(@"product info");
        NSLog(@"SKProduct描述信息:%@", [skProduct description]);
        NSLog(@"产品标题:%@" , skProduct.localizedTitle);
        NSLog(@"产品描述信息: %@" , skProduct.localizedDescription);
        NSLog(@"价格: %@" , skProduct.price);
        NSLog(@"Product id: %@" , skProduct.productIdentifier);
        
        IOSProduct *iosProduct = new IOSProduct;
        iosProduct->productIdentifier = std::string([skProduct.productIdentifier UTF8String]);
        iosProduct->localizedTitle = std::string([skProduct.localizedTitle UTF8String]);
        iosProduct->localizedDescription = std::string([skProduct.localizedDescription UTF8String]);
        
        // locale price to string
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:skProduct.priceLocale];
        NSString *priceStr = [formatter stringFromNumber:skProduct.price];
        [formatter release];
        iosProduct->localizedPrice = std::string([priceStr UTF8String]);
        
        iosProduct->index = index;
        iosProduct->isValid = isValid;
        _iosiap->iOSProducts.push_back(iosProduct);
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"----------反馈信息结束--------------");
    _iosiap->delegate->onRequestProductsFinish();
    [request.delegate release];
    [request release];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    NSLog(@"-------弹出错误信息----------");
    _iosiap->delegate->onRequestProductsError([error code]);
    
    [[[[UIAlertView alloc] initWithTitle:@"Error"
                                 message:[error localizedDescription]
                                delegate:NULL
                       cancelButtonTitle:@"Close"
                       otherButtonTitles: nil] autorelease] show];
}

@end

//******************************************************************************
// class iAPTransactionObserver
//******************************************************************************
#pragma mark - class iAPTransactionObserver

@interface iAPTransactionObserver : NSObject<SKPaymentTransactionObserver>
@property (nonatomic, assign) IOSiAP *iosiap;
@end

@implementation iAPTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"-----paymentQueue: updatedTransactions:--------");
    
    for (SKPaymentTransaction *transaction in transactions) {
        std::string identifier([transaction.payment.productIdentifier UTF8String]);
        IOSiAPPaymentEvent event;
        
        switch (transaction.transactionState) {
                // 商品添加进列表
            case SKPaymentTransactionStatePurchasing:
                event = IOSIAP_PAYMENT_PURCHASING;
                return;
                // 交易完成
            case SKPaymentTransactionStatePurchased:
                event = IOSIAP_PAYMENT_PURCHAED;
                break;
                // 交易失败
            case SKPaymentTransactionStateFailed:
                event = IOSIAP_PAYMENT_FAILED;
                NSLog(@"==ios payment error:%@", transaction.error);
                break;
                // 已经购买过该商品
            case SKPaymentTransactionStateRestored:
                // NOTE: consumble payment is NOT restorable
                event = IOSIAP_PAYMENT_RESTORED;
                break;
        }
        
        _iosiap->delegate->onPaymentEvent(identifier, event, transaction.payment.quantity);
        if (event != IOSIAP_PAYMENT_PURCHASING) {
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
     NSLog(@"-----paymentQueue: removedTransactions:--------");
    
    for (SKPaymentTransaction *transaction in transactions) {
        std::string identifier([transaction.payment.productIdentifier UTF8String]);
        _iosiap->delegate->onPaymentEvent(identifier, IOSIAP_PAYMENT_REMOVED, transaction.payment.quantity);
    }
}

@end


//******************************************************************************
// class IOSiAP
//******************************************************************************
#pragma mark - class IOSiAP

IOSiAP::IOSiAP():
skProducts(NULL),
delegate(NULL)
{
    skTransactionObserver = [[iAPTransactionObserver alloc] init];
    ((iAPTransactionObserver *)skTransactionObserver).iosiap = this;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:(iAPTransactionObserver *)skTransactionObserver];
}

IOSiAP::~IOSiAP()
{
    if (skProducts) {
        [(NSArray *)(skProducts) release];
    }
    
    std::vector <IOSProduct *>::iterator iterator;
    for (iterator = iOSProducts.begin(); iterator != iOSProducts.end(); iterator++) {
        IOSProduct *iosProduct = *iterator;
        delete iosProduct;
    }
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:(iAPTransactionObserver *)skTransactionObserver];
    [(iAPTransactionObserver *)skTransactionObserver release];
}

// 获取商品信息列表
void IOSiAP::requestProducts(std::vector <std::string> &productIdentifiers)
{
    NSLog(@"---------请求对应的产品信息------------");
    NSMutableSet *set = [NSMutableSet setWithCapacity:productIdentifiers.size()];
    std::vector <std::string>::iterator iterator;
    for (iterator = productIdentifiers.begin(); iterator != productIdentifiers.end(); iterator++) {
        [set addObject:[NSString stringWithUTF8String:(*iterator).c_str()]];
    }
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    iAPProductsRequestDelegate *delegate = [[iAPProductsRequestDelegate alloc] init];
    delegate.iosiap = this;
    productsRequest.delegate = delegate;
    [productsRequest start];
}

// 由ID得到商品信息
IOSProduct *IOSiAP::iOSProductByIdentifier(std::string &identifier)
{
    std::vector <IOSProduct *>::iterator iterator;
    for (iterator = iOSProducts.begin(); iterator != iOSProducts.end(); iterator++) {
        IOSProduct *iosProduct = *iterator;
        if (iosProduct->productIdentifier == identifier) {
            return iosProduct;
        }
    }

    return NULL;
}

// 购买商品
void IOSiAP::paymentWithProduct(IOSProduct *iosProduct, int quantity)
{
    NSLog(@"---------发送购买请求------------");
    if ([SKPaymentQueue canMakePayments]) {
        NSLog(@"允许程序内付费购买");
        SKProduct *skProduct = [(NSArray *)(skProducts) objectAtIndex:iosProduct->index];
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:skProduct];
        payment.quantity = quantity;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else{
        NSLog(@"不允许程序内付费购买");
        [[[[UIAlertView alloc] initWithTitle:@"Error"
                                   message:@"You don't allow app to purchase."
                                  delegate:nil
                         cancelButtonTitle:@"Close"
                         otherButtonTitles:nil] autorelease]show];
    }
}