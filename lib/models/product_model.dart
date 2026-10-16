class ProductModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool soldOut;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.soldOut,
  });

  factory ProductModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Khác',
      soldOut: map['soldOut'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'soldOut': soldOut,
    };
  }
}