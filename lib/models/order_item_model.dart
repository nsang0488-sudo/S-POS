class OrderItemModel {
  final String fName;
  final double price;
  int qty;
  bool done;

  OrderItemModel({
    required this.fName,
    required this.price,
    required this.qty,
    required this.done,
  });

  factory OrderItemModel.fromMap(Map<dynamic, dynamic> map) {
    return OrderItemModel(
      fName: map['fName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      qty: map['qty'] ?? 1,
      done: map['done'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fName': fName,
      'price': price,
      'qty': qty,
      'done': done,
    };
  }
}