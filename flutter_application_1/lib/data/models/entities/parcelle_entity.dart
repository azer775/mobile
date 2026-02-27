import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart';

class ParcelleEntity extends BaseEntity {          
  String? codeParcelle;
  String? referenceCadastrale;
  // Legacy string address fields (kept for backward compatibility)
  String? commune;
  String? quartier;
  String? rueAvenue;
  String? numeroAdresse;
  // New FK-based address fields (matching contribuable pattern)
  int? communeId;
  int? quartierId;
  int? avenueId;
  String? rue;
  String? numeroParcelle;
  double? superficieM2;
  double? gpsLat;
  double? gpsLon;
  StatutParcelle statutParcelle;
  DateTime? dateCreation;
  DateTime? dateMiseAJour;
  String? sourceDonnee;
  int syncStatus;
  String? syncError;
  int syncAttempts;
  DateTime? lastSyncAt;

  ParcelleEntity({
    super.id,
    this.codeParcelle,
    this.referenceCadastrale,
    this.commune,
    this.quartier,
    this.rueAvenue,
    this.numeroAdresse,
    this.communeId,
    this.quartierId,
    this.avenueId,
    this.rue,
    this.numeroParcelle,
    this.superficieM2,
    this.gpsLat,
    this.gpsLon,
    required this.statutParcelle,
    this.dateCreation,
    this.dateMiseAJour,
    this.sourceDonnee,
    this.syncStatus = 0,
    this.syncError,
    this.syncAttempts = 0,
    this.lastSyncAt,
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
      'commune_id': communeId,
      'quartier_id': quartierId,
      'avenue_id': avenueId,
      'rue': rue,
      'numero_parcelle': numeroParcelle,
      'superficie_m2': superficieM2,
      'gps_lat': gpsLat,
      'gps_lon': gpsLon,
      'statut_parcelle': statutParcelle.value,
      'date_creation': dateCreation?.toIso8601String(),
      'date_mise_a_jour': dateMiseAJour?.toIso8601String(),
      'source_donnee': sourceDonnee,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
      'sync_error': syncError,
      'sync_attempts': syncAttempts,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDto() {
    final dto = <String, dynamic>{
      'statutParcelle': statutParcelle.value,
    };

    void addIfNotNull(String key, dynamic value) {
      if (value != null) {
        dto[key] = value;
      }
    }

    addIfNotNull('codeParcelle', codeParcelle);
    addIfNotNull('referenceCadastrale', referenceCadastrale);
    addIfNotNull('numeroAdresse', numeroAdresse);
    addIfNotNull('rue', rue);
    addIfNotNull('numeroParcelle', numeroParcelle);
    addIfNotNull('superficieM2', superficieM2);
    addIfNotNull('gpsLat', gpsLat);
    addIfNotNull('gpsLon', gpsLon);
    addIfNotNull('sourceDonnee', sourceDonnee);
    addIfNotNull('commune', communeId);
    addIfNotNull('quartier', quartierId);
    addIfNotNull('rueAvenue', avenueId);

    return dto;
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
      communeId: map['commune_id'] as int?,
      quartierId: map['quartier_id'] as int?,
      avenueId: map['avenue_id'] as int?,
      rue: map['rue'] as String?,
      numeroParcelle: map['numero_parcelle'] as String?,
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
        syncStatus: map['sync_status'] as int? ?? 0,
        syncError: map['sync_error'] as String?,
        syncAttempts: map['sync_attempts'] as int? ?? 0,
        lastSyncAt: map['last_sync_at'] != null
          ? DateTime.parse(map['last_sync_at'] as String)
          : null,
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
    int? communeId,
    int? quartierId,
    int? avenueId,
    String? rue,
    String? numeroParcelle,
    double? superficieM2,
    double? gpsLat,
    double? gpsLon,
    StatutParcelle? statutParcelle,
    DateTime? dateCreation,
    DateTime? dateMiseAJour,
    String? sourceDonnee,
    int? syncStatus,
    String? syncError,
    int? syncAttempts,
    DateTime? lastSyncAt,
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
      communeId: communeId ?? this.communeId,
      quartierId: quartierId ?? this.quartierId,
      avenueId: avenueId ?? this.avenueId,
      rue: rue ?? this.rue,
      numeroParcelle: numeroParcelle ?? this.numeroParcelle,
      superficieM2: superficieM2 ?? this.superficieM2,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      statutParcelle: statutParcelle ?? this.statutParcelle,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
      sourceDonnee: sourceDonnee ?? this.sourceDonnee,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}