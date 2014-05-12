//
//  IOSiAP.h
//  iAP_JSBinding
//
//  Created by NanFeng on 1/14/14.
//
//

#ifndef __iAP_JSBinding__IOSiAP__
#define __iAP_JSBinding__IOSiAP__

#include <iostream>
#include <vector>

// 商品信息
class IOSProduct
{
public:
    std::string productIdentifier;      // 商品ID
    std::string localizedTitle;         // 商品名称（显示在界面的）
    std::string localizedDescription;   // 商品描述
    std::string localizedPrice;         // 商品的价格（显示在界面的）(has be localed, just display it on UI.)
    bool isValid;                       // 表示商品有否可以购买
    int index;                          // 用于商品排序(internal use : index of skProducts)
};

// 支付返回消息类型
typedef enum {
    IOSIAP_PAYMENT_PURCHASING,          // just notify, UI do nothing
    IOSIAP_PAYMENT_PURCHAED,            // need unlock App Functionality
    IOSIAP_PAYMENT_FAILED,              // remove waiting on UI, tall user payment was failed
    IOSIAP_PAYMENT_RESTORED,            // need unlock App Functionality, consumble payment No need to care about this.
    IOSIAP_PAYMENT_REMOVED,             // remove waiting on UI
} IOSiAPPaymentEvent;

// 请求商品信息的伪托
class IOSiAPDelegate
{
public:
    virtual ~IOSiAPDelegate() {}
    // for requestProduct
    virtual void onRequestProductsFinish(void) = 0;
    virtual void onRequestProductsError(int code) = 0;
    // for payment
    virtual void onPaymentEvent(std::string &identifier, IOSiAPPaymentEvent event, int quantity) = 0;
};

class IOSiAP
{
public:
    IOSiAP();
    ~IOSiAP();
    
    // 获取商品信息列表
    void requestProducts(std::vector <std::string> &productIdentifiers);
    // 由ID得到商品信息
    IOSProduct *iOSProductByIdentifier(std::string &identifier);
    // 购买商品
    void paymentWithProduct(IOSProduct *iosProduct, int quantity = 1);
    
    // 回调
    IOSiAPDelegate *delegate;
    
    // ===  internal use for object-c class ===
    void *skProducts;                       // OC请求回来的商品信息列表 object-c SKProduct
    void *skTransactionObserver;            // 消息监听和转发 object-c TransactionObserver
    
    std::vector<IOSProduct *> iOSProducts;  // 转换为C++后的商品信息列表
};

#endif /* defined(__iAP_JSBinding__IOSiAP__) */
