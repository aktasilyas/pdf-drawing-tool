// RevenueCat data source wrapping purchases_flutter calls.
import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatDatasource {
  StreamController<CustomerInfo>? _customerInfoController;

  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  Future<CustomerInfo> purchase(Package package) async {
    return Purchases.purchasePackage(package);
  }

  Future<CustomerInfo> restorePurchases() async {
    return Purchases.restorePurchases();
  }

  Stream<CustomerInfo> watchCustomerInfo() {
    _customerInfoController ??= StreamController<CustomerInfo>.broadcast(
      onListen: () {
        Purchases.addCustomerInfoUpdateListener((info) {
          _customerInfoController?.add(info);
        });
      },
    );
    return _customerInfoController!.stream;
  }
}
