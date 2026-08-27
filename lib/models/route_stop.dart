class RouteStop {
  final String id;
  final String organizationId;
  final String routeId;
  final String assistedPersonId;
  final int stopOrder;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? personName;
  final String? personAddress;
  final String? personMapsLink;
  final String? personPhone;

  RouteStop({
    required this.id,
    required this.organizationId,
    required this.routeId,
    required this.assistedPersonId,
    required this.stopOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.personName,
    this.personAddress,
    this.personMapsLink,
    this.personPhone,

  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    final person = map['assisted_people'] as Map<String,dynamic>?;

    return RouteStop(
      id: map['id'],
      organizationId: map['organization_id'],
      routeId: map['route_id'],
      assistedPersonId: map['assisted_person_id'],
      stopOrder: map['stop_order'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      personName: person?['name'] as String?,
      personAddress: person?['main_address'] as String?,
      personMapsLink: person?['maps_link'] as String?,  
      personPhone: person?['phone'] as String?,
    );
  }
}