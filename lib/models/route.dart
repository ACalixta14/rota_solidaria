class Route {
  final String id;
  final String organizationId;
  final DateTime routeDate;
  final String status;

  final int? startMileage;
  final int? endMileage;

  final String? driverName;

  final DateTime? startedAt;
  final DateTime? completedAt;

  final String createdBy;
  final String? startedBy;
  final String? completedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  Route({
    required this.id,
    required this.organizationId,
    required this.routeDate,
    required this.status,
    this.startMileage,
    this.endMileage,
    this.driverName,
    this.startedAt,
    this.completedAt,
    required this.createdBy,
    this.startedBy,
    this.completedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'],
      organizationId: map['organization_id'],
      routeDate: DateTime.parse(map['route_date']),
      status: map['status'],
      startMileage: map['start_mileage'],
      endMileage: map['end_mileage'],
      driverName: map['driver_name'] as String?,
      startedAt: map['started_at'] == null
          ? null
          : DateTime.parse(map['started_at']),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at']),
      createdBy: map['created_by'],
      startedBy: map['started_by'],
      completedBy: map['completed_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}