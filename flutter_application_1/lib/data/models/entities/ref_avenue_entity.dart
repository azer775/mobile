import '../base/base_entity.dart';

/// Reference table for avenues
/// This is a reference/lookup table populated manually via SQL
class RefAvenueEntity extends BaseEntity {
  String libelle;

  RefAvenueEntity({
    super.id,
    required this.libelle,
  });

  @override
  String get tableName => 'ref_avenue';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
    };
  }

  factory RefAvenueEntity.fromMap(Map<String, dynamic> map) {
    return RefAvenueEntity(
      id: map['id'] as int?,
      libelle: map['libelle'] as String,
    );
  }

  @override
  String toString() => libelle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefAvenueEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
