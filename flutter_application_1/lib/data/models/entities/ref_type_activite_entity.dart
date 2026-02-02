import '../base/base_entity.dart';

/// Reference table for activity types (types d'activité)
/// This is a reference/lookup table populated manually via SQL
class RefTypeActiviteEntity extends BaseEntity {
  String libelle;

  RefTypeActiviteEntity({
    super.id,
    required this.libelle,
  });

  @override
  String get tableName => 'ref_type_activite';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory RefTypeActiviteEntity.fromMap(Map<String, dynamic> map) {
    return RefTypeActiviteEntity(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => libelle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefTypeActiviteEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
