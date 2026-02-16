import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart';

class ParcelleEntity extends BaseEntity {          
  String? codeParcelle;
  String? referenceCadastrale;
  String? commune;
  String? quartier;
  String? rueAvenue;
  String? numeroAdresse;
  double? superficieM2;
  double? gpsLat;
  double? gpsLon;
  StatutParcelle statutParcelle;
  DateTime? dateCreation;
  DateTime? dateMiseAJour;
  String? sourceDonnee;

  ParcelleEntity({
    super.id,
    this.codeParcelle,
    this.referenceCadastrale,
    this.commune,
    this.quartier,
    this.rueAvenue,
    this.numeroAdresse,
    this.superficieM2,
    this.gpsLat,
    this.gpsLon,
    required this.statutParcelle,
    this.dateCreation,
    this.dateMiseAJour,
    this.sourceDonnee,
    super.createdAt,
    super.updatedAt,
  });

  String? get mainAddress => 
      [numeroAdresse, rueAvenue, quartier, commune]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');

  bool get hasGps => gpsLat != null && gpsLon != null;

  @override
  String get tableName => 'parcelles';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code_parcelle': codeParcelle,
      'reference_cadastrale': referenceCadastrale,
      'commune': commune,
      'quartier': quartier,
      'rue_avenue': rueAvenue,
      'numero_adresse': numeroAdresse,
      'superficie_m2': superficieM2,
      'gps_lat': gpsLat,
      'gps_lon': gpsLon,
      'statut_parcelle': statutParcelle.value,
      'date_creation': dateCreation?.toIso8601String(),
      'date_mise_a_jour': dateMiseAJour?.toIso8601String(),
      'source_donnee': sourceDonnee,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ParcelleEntity.fromMap(Map<String, dynamic> map) {
    return ParcelleEntity(
      id: map['id'] as int?,
      codeParcelle: map['code_parcelle'] as String?,
      referenceCadastrale: map['reference_cadastrale'] as String?,
      commune: map['commune'] as String?,
      quartier: map['quartier'] as String?,
      rueAvenue: map['rue_avenue'] as String?,
      numeroAdresse: map['numero_adresse'] as String?,
      superficieM2: map['superficie_m2'] != null ? (map['superficie_m2'] as num).toDouble() : null,
      gpsLat: map['gps_lat'] != null ? (map['gps_lat'] as num).toDouble() : null,
      gpsLon: map['gps_lon'] != null ? (map['gps_lon'] as num).toDouble() : null,
      statutParcelle: StatutParcelle.fromString(map['statut_parcelle'] as String?),
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'] as String)
          : null,
      dateMiseAJour: map['date_mise_a_jour'] != null
          ? DateTime.parse(map['date_mise_a_jour'] as String)
          : null,
      sourceDonnee: map['source_donnee'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  ParcelleEntity copyWith({
    int? id,
    String? codeParcelle,
    String? referenceCadastrale,
    String? commune,
    String? quartier,
    String? rueAvenue,
    String? numeroAdresse,
    double? superficieM2,
    double? gpsLat,
    double? gpsLon,
    StatutParcelle? statutParcelle,
    DateTime? dateCreation,
    DateTime? dateMiseAJour,
    String? sourceDonnee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParcelleEntity(
      id: id ?? this.id,
      codeParcelle: codeParcelle ?? this.codeParcelle,
      referenceCadastrale: referenceCadastrale ?? this.referenceCadastrale,
      commune: commune ?? this.commune,
      quartier: quartier ?? this.quartier,
      rueAvenue: rueAvenue ?? this.rueAvenue,
      numeroAdresse: numeroAdresse ?? this.numeroAdresse,
      superficieM2: superficieM2 ?? this.superficieM2,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      statutParcelle: statutParcelle ?? this.statutParcelle,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
      sourceDonnee: sourceDonnee ?? this.sourceDonnee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}