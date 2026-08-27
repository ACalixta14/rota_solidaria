// atributos dos assistidos
class AssistedPerson {
  final String id;
  final String? name;
  final String? nickname;

  // localização principal
  final String? mainAddress;
  final String? mapsLink;
  final double? latitude;
  final double? longitude;

  // contacto
  final String? phone;

  final String? publicNotes;

  // ativo ou inativo
  final bool isActive;
  final String? deactivationReason;
  final String? deactivatedBy;
  final DateTime? deactivatedAt;

  // construtor
  AssistedPerson({
    required this.id,
    this.name,
    this.nickname,
    this.mainAddress,
    this.mapsLink,
    this.latitude,
    this.longitude,
    this.phone,
    this.publicNotes,

    // ativo ou inativo
    required this.isActive,
    this.deactivationReason,
    this.deactivatedBy,
    this.deactivatedAt,
  });

  // fromMap é a tradução entre o formato do banco
  // e o objeto que o Flutter utiliza
  factory AssistedPerson.fromMap(Map<String, dynamic> map) {
    return AssistedPerson(
      id: map['id'],
      name: map['name'],
      nickname: map['nickname'],
      mainAddress: map['main_address'],
      mapsLink: map['maps_link'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      phone: map['phone'],
      publicNotes: map['public_notes'],
      isActive: map['is_active'] as bool,
      deactivationReason: map['deactivation_reason'] as String?,
      deactivatedBy: map['deactivated_by'] as String?,
      deactivatedAt: map['deactivated_at'] == null
          ? null
          : DateTime.parse(map['deactivated_at']),
    );
  }
}