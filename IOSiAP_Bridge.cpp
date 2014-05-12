//
//  IOSiAP_Bridge.cpp
//  TinyBugs2
//
//  Created by user on 14-3-6.
//
//

#include "IOSiAP_Bridge.h"

static IOSiAP_Bridge *s_SharedIOSiAP_Bridge = NULL;

IOSiAP_Bridge* IOSiAP_Bridge::sharedIOSiAP_Bridge(void){
    
    if (!s_SharedIOSiAP_Bridge){
        s_SharedIOSiAP_Bridge = new IOSiAP_Bridge();
    }
    
    return s_SharedIOSiAP_Bridge;
}

IOSiAP_Bridge::IOSiAP_Bridge(){
    
    iap = new IOSiAP();
    iap->delegate = this;
    
    m_bFinishRequest = false;
}

IOSiAP_Bridge::~IOSiAP_Bridge(){
    
    s_SharedIOSiAP_Bridge = NULL;
    
    delete iap;
    iap = NULL;
}

void IOSiAP_Bridge:: requestProducts(std::vector <std::string> &productIdentifiers){
    
    iap->requestProducts(productIdentifiers);
}

void IOSiAP_Bridge::buyProductByID(std::vector <std::string> &productIdentifiers){

    //必须在onRequestProductsFinish后才能去请求iAP产品数据，然后可以发起付款请求。
    if (m_bFinishRequest) {
        for (std::vector<std::string>::iterator it = productIdentifiers.begin(); it != productIdentifiers.end(); ++it) {
            std::string identifier = *it;
            IOSProduct *product = iap->iOSProductByIdentifier(identifier);
            if (product != NULL) {
                iap->paymentWithProduct(product/*第二个参数默认为1，可以在此传入其他数量*/);
            }
            else{
                std::cout << "IOSiAP_Bridge::buyProductByID:product==NULL,identifier=" << identifier << std::endl;
            }
        }
    }
}

void IOSiAP_Bridge::buySuccess(std::string &identifier){

//    if (identifier == COINS_ID_0) {
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_0);
//    }
//    else if (identifier == COINS_ID_1){
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_1);
//    }
//    else if (identifier == COINS_ID_2){
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_2);
//    }
//    else if (identifier == COINS_ID_3){
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_3);
//    }
//    else if (identifier == COINS_ID_4){
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_4);
//    }
//    else if (identifier == COINS_ID_5){
//        FileManager::setCoinsCount(FileManager::getCoinsCount() + COINS_COUNT_5);
//    }
//    else{
//        std::cout << "error IOSiAP_Bridge::buySuccess:identifier = " << identifier << std::endl;
//    }
//    // 推送通知
//    CCNotificationCenter::sharedNotificationCenter()->postNotification(NOTIFICATION_REFRESH_COINS, NULL);
}

//******************************************************************************
// IOSiAPDelegate方法
//******************************************************************************
#pragma mark - Function int IOSiAPDelegate
void IOSiAP_Bridge::onRequestProductsFinish(void){
    
    m_bFinishRequest = true;
    std::cout << "IOSiAP_Bridge::onRequestProductsFinish " << std::endl;
}

void IOSiAP_Bridge::onRequestProductsError(int code){
    
    m_bFinishRequest = false;
    // 这里requestProducts出错了，不能进行后面的所有操作。
    std::cout << "IOSiAP_Bridge::onRequestProductsError:code = " << code << std::endl;
}

void IOSiAP_Bridge::onPaymentEvent(std::string &identifier, IOSiAPPaymentEvent event, int quantity){
    
    if (event == IOSIAP_PAYMENT_PURCHAED) {
        // 付款成功了，可以把金币发给玩家了。
        std::cout << "IOSiAP_Bridge::onPaymentEvent:购买成功！" << std::endl;
        this->buySuccess(identifier);
    }
    else{
        // 其他状态依情况处理掉。
        
    }
}