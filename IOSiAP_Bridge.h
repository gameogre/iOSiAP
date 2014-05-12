//
//  IOSiAP_Bridge.h
//  TinyBugs2
//
//  Created by user on 14-3-6.
//
//

#ifndef __TinyBugs2__IOSiAP_Bridge__
#define __TinyBugs2__IOSiAP_Bridge__

#include <iostream>
#include "IOSiAP.h"

class IOSiAP_Bridge : public IOSiAPDelegate
{
public:
    ~IOSiAP_Bridge();
    
    static IOSiAP_Bridge* sharedIOSiAP_Bridge(void);
    
    // 根据商品ID获取商品信息
    void requestProducts(std::vector <std::string> &productIdentifiers);
    
    // 购买产品
    void buyProductByID(std::vector <std::string> &productIdentifiers);
    
    // 购买成功后本地数据处理
    void buySuccess(std::string &identifier);
    
    //**************************************************************************
    // IOSiAPDelegate方法
    //**************************************************************************
    virtual void onRequestProductsFinish(void);
    virtual void onRequestProductsError(int code);
    virtual void onPaymentEvent(std::string &identifier, IOSiAPPaymentEvent event, int quantity);
    
protected:
    IOSiAP_Bridge();
    
    IOSiAP *iap;
    bool m_bFinishRequest;
};

#endif /* defined(__TinyBugs2__IOSiAP_Bridge__) */
