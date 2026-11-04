
class RouteInventoryItem {
  final String id;
  final String organizationId;
  final String routeId;
  final String itemName;
  final int initialQuantity;
  final int remainingQuantity;
  final DateTime createdAt;

  const RouteInventoryItem({
    required this.id,
    required this.organizationId,
    required this.routeId,
    required this.itemName,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.createdAt,
  });

  factory RouteInventoryItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return RouteInventoryItem(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      routeId: map['route_id'] as String,
      itemName: map['item_name'] as String,
      initialQuantity: map['initial_quantity'] as int,
      remainingQuantity: map['remaining_quantity'] as int,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
    );
  }
}
