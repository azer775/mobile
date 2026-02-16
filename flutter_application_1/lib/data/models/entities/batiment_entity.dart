import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart';

class BatimentEntity extends BaseEntity {
  int? parcelleId;         // FK to ParcelleEntity.id (int)
  TypeBatiment typeBatiment;
  int? nombreEtages;
  int? anneeConstruction;
  double? surfaceBatieM2;
  UsagePrincipal usagePrincipal;
  StatutBatiment statutBatiment;

  BatimentEntity({
    super.id,
    this.parcelleId,
    required this.typeBatiment,
    this.nombreEtages,
    this.anneeConstruction,
    this.surfaceBatieM2,
    required this.usagePrincipal,
    required this.statutBatiment,
    super.createdAt,
    super.updatedAt,
  });

  String get displayInfo => 
      '${typeBatiment.value} – ${usagePrincipal.value} (${nombreEtages ?? "?"} étages)';

  @override
  String get tableName => 'batiments';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parcelle_id': parcelleId,
      'type_batiment': typeBatiment.value,
      'nombre_etages': nombreEtages,
      'annee_construction': anneeConstruction,
      'surface_batie_m2': surfaceBatieM2,
      'usage_principal': usagePrincipal.value,
      'statut_batiment': statutBatiment.value,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BatimentEntity.fromMap(Map<String, dynamic> map) {
    return BatimentEntity(
      id: map['id'] as int?,
      parcelleId: map['parcelle_id'] as int?,
      typeBatiment: TypeBatiment.fromString(map['type_batiment'] as String?),
      nombreEtages: map['nombre_etages'] as int?,
      anneeConstruction: map['annee_construction'] as int?,
      surfaceBatieM2: map['surface_batie_m2'] != null 
          ? (map['surface_batie_m2'] as num).toDouble() 
          : null,
      usagePrincipal: UsagePrincipal.fromString(map['usage_principal'] as String?),
      statutBatiment: StatutBatiment.fromString(map['statut_batiment'] as String?),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  BatimentEntity copyWith({
    int? id,
    int? parcelleId,
    TypeBatiment? typeBatiment,
    int? nombreEtages,
    int? anneeConstruction,
    double? surfaceBatieM2,
    UsagePrincipal? usagePrincipal,
    StatutBatiment? statutBatiment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatimentEntity(
      id: id ?? this.id,
      parcelleId: parcelleId ?? this.parcelleId,
      typeBatiment: typeBatiment ?? this.typeBatiment,
      nombreEtages: nombreEtages ?? this.nombreEtages,
      anneeConstruction: anneeConstruction ?? this.anneeConstruction,
      surfaceBatieM2: surfaceBatieM2 ?? this.surfaceBatieM2,
      usagePrincipal: usagePrincipal ?? this.usagePrincipal,
      statutBatiment: statutBatiment ?? this.statutBatiment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}