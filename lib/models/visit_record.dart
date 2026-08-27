

//declaração de variáveis das visitas
class VisitRecord {
  final String id;
  final String assistedPersonId;
  final String? volunteerId;
  final bool wasFound;
  final String? observation;
  final String? requestedItems;
  final DateTime createdAt;
  final String? routeId;
  final String? routeStopId;
  final String? foodStatus;
  final String? notFoundReason;
  final String? emotionalState;
  final String? physicalCondition;

//construtor
  VisitRecord({
    required this.id,
    required this.assistedPersonId,
    this.volunteerId,
    required this.wasFound,
    this.observation,
    this.requestedItems,
    required this.createdAt,
    this.routeId,
    this.routeStopId,
    this.foodStatus,
    this.notFoundReason,
    this.emotionalState,
    this.physicalCondition,
  });
//construtor via maps que puxa do bd
  factory VisitRecord.fromMap(Map<String, dynamic> map) {
    return VisitRecord(
      id: map['id'] as String,
      assistedPersonId: map['assisted_person_id'] as String,
      volunteerId: map['volunteer_id'] as String?,
      wasFound: map['was_found'] as bool,
      observation: map['observation'] as String?,
      requestedItems: map['requested_items'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      routeId: map['route_id'] as String?,
      routeStopId: map['route_stop_id'] as String?,
      foodStatus: map['food_status'] as String?,
      notFoundReason: map['not_found_reason'] as String?,
      emotionalState: map['emotional_state'] as String?,
      physicalCondition: map['physical_condition'] as String?,
    );
  }
}