import '../base/base_entity.dart';

/// Reference table for quartiers
/// This is a reference/lookup table populated manually via SQL
class RefQuartierEntity extends BaseEntity {
  String libelle;

  RefQuartierEntity({
    super.id,
    required this.libelle,
  });

  @override
  String get tableName => 'ref_quartier';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory RefQuartierEntity.fromMap(Map<String, dynamic> map) {
    return RefQuartierEntity(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => libelle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefQuartierEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
