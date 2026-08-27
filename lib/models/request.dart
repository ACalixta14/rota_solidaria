class Request {
  final String id;
  final String assistedPersonId;
  final String? visitRecordId;

  final String description;
  final String status;

  final String? createdBy;
  final String? fulfilledBy;

  final DateTime? fulfilledAt;
  final DateTime? canceledAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String organizationId;

  final String? personName;

  Request({
    required this.id,
    required this.assistedPersonId,
    this.visitRecordId,
    required this.description,
    required this.status,
    this.createdBy,
    this.fulfilledBy,
    this.fulfilledAt,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.organizationId,
    this.personName,
  });

  factory Request.fromMap(Map<String, dynamic> map) {
    final person =
    map['assisted_people'] as Map<String, dynamic>?;
    
    return Request(
      id: map['id'] as String,
      assistedPersonId: map['assisted_person_id'] as String,
      visitRecordId: map['visit_record_id'] as String?,
      description: map['description'] as String,
      status: map['status'] as String,
      createdBy: map['created_by'] as String?,
      fulfilledBy: map['fulfilled_by'] as String?,
      fulfilledAt: map['fulfilled_at'] == null
          ? null
          : DateTime.parse(map['fulfilled_at'] as String),
      canceledAt: map['canceled_at'] == null
          ? null
          : DateTime.parse(map['canceled_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      organizationId: map['organization_id'] as String,
      personName: person?['name'] as String?,
    );
  }
}