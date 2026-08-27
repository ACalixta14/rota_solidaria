class RequestFulfillment {
  final String id;
  final String organizationId;
  final String requestId;

  final String description;
  final String deliveredBy;

  final DateTime deliveredAt;
  final bool completesRequest;
  final DateTime createdAt;

  RequestFulfillment({
    required this.id,
    required this.organizationId,
    required this.requestId,
    required this.description,
    required this.deliveredBy,
    required this.deliveredAt,
    required this.completesRequest,
    required this.createdAt,
  });

  factory RequestFulfillment.fromMap(
    Map<String, dynamic> map,
  ) {
    return RequestFulfillment(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      requestId: map['request_id'] as String,
      description: map['description'] as String,
      deliveredBy: map['delivered_by'] as String,
      deliveredAt: DateTime.parse(
        map['delivered_at'] as String,
      ),
      completesRequest:
          map['completes_request'] as bool,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
    );
  }
}