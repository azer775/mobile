import '../base/base_entity.dart';

/// Reference table for communes
/// This is a reference/lookup table populated manually via SQL
class RefCommuneEntity extends BaseEntity {
  String libelle;

  RefCommuneEntity({
    super.id,
    required this.libelle,
  });

  @override
  String get tableName => 'ref_commune';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory RefCommuneEntity.fromMap(Map<String, dynamic> map) {
    return RefCommuneEntity(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => libelle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefCommuneEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
