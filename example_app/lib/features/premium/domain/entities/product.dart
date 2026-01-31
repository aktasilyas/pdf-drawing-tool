/// Domain entity describing a purchasable premium product.
library;

enum ProductType { subscription, lifetime }

/// Domain entity describing a purchasable premium product.
class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final String currencyCode;
  final ProductType type;
  final String? subscriptionPeriod;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.type,
    this.subscriptionPeriod,
  });
}
