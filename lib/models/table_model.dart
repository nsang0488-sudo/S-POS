import 'order_item_model.dart';

class TableModel {
  final String status;
  final String? startTime;
  final List<OrderItemModel> items;
  final bool needsServing;

  TableModel({
    required this.status,
    this.startTime,
    required this.items,
    required this.needsServing,
  });

  factory TableModel.fromMap(Map<dynamic, dynamic> map) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((itemMap) => OrderItemModel.fromMap(itemMap))
        .toList();

    return TableModel(
      status: map['status'] ?? 'white',
      startTime: map['startTime'],
      items: parsedItems,
      needsServing: map['needsServing'] ?? false,
    );
  }
}