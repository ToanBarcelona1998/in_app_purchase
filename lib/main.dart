import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_ios/store_kit_wrappers.dart';
import 'package:in_app_purchase_ios/in_app_purchase_ios.dart';
void main() => runApp(const MaterialApp(home: MyApp(),));
class MyApp extends StatefulWidget {
  const MyApp({Key ?key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final List<String> _kProductIds = <String>["abcxyz"];

  @override
  void initState() {
    super.initState();
    _listenStore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showPurchaseByStore(),
          child: const Text("Show purchase"),
        ),
      ),
    );
  }

  void showPurchaseByStore() async {
    //fuction này hoạt động với điều kiện user đăng nhập trên ch play or app store
    // Sản phẩm đã được set trên store
    if(Platform.isIOS){
      InAppPurchase.instance.restorePurchases();
      var transactions = await SKPaymentQueueWrapper().transactions();
      transactions.forEach((skPaymentTransactionWrapper) {
        SKPaymentQueueWrapper().finishTransaction(skPaymentTransactionWrapper);
      });
    }

    try {
      final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kProductIds.toSet());
      PurchaseParam param = PurchaseParam(productDetails: response.productDetails[0]); // Lấy ra sản phẩm đang bán thôi.

      // Yêu cầu show ra UI thanh toán của google
      bool isPurchaseSuccess = await InAppPurchase.instance.buyConsumable(purchaseParam: param);

      // Nếu người dùng click thanh toán và thanh toán thành công tại hàm instance sẽ lắng nghe click thanh toán và trạng thái của nó.
      // Show UI cho hợp lý.

    } catch (err) {
     print(err.toString());

    } catch (err) {
      print(err.toString());
    }

  }


  Future<void> _listenStore() async {
    // Lắng nghe
    // xử lý logic khi thanh toán thành công tạo ra stream lắng nghe để show UI hợp lý...
    Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) async {
      for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.purchaseID != null &&
            purchaseDetails.purchaseID!.isNotEmpty &&
            purchaseDetails.status == PurchaseStatus.purchased) {
          try {
            if (purchaseDetails.pendingCompletePurchase) {
              // Thông báo là thanh toán thành công lại cho Store.
              await InAppPurchase.instance
                  .completePurchase(purchaseDetails);
            }
            else{
              print("Fail pendding purchase not complete".toUpperCase());
            }

          } catch (err) {
            print("Error: " + err.toString());
          }
        }
      }
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
  }
}


