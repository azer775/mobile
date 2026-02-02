import '../base/base_entity.dart';

/// Reference table for zone types (types de zone)
/// This is a reference/lookup table populated manually via SQL
class RefZoneTypeEntity extends BaseEntity {
  String libelle;

  RefZoneTypeEntity({
    super.id,
    required this.libelle,
  });

  @override
  String get tableName => 'ref_zone_type';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory RefZoneTypeEntity.fromMap(Map<String, dynamic> map) {
    return RefZoneTypeEntity(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => libelle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefZoneTypeEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
