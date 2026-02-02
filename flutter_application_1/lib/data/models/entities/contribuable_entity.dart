import 'dart:convert';
import '../base/base_entity.dart';
import '../enums/contribuable_enums.dart';

/// Contribuable (Taxpayer) Entity for database storage
class ContribuableEntity extends BaseEntity {
  String? nif;
  TypeNif? typeNif;
  TypeContribuable typeContribuable;
  String? nom;
  String? postNom;
  String? prenom;
  String? raisonSociale;
  String telephone1;
  String? telephone2;
  String? email;
  String adresse;
  OrigineFiche origineFiche;
  int? activiteId; // Foreign key to ref_type_activite
  int? zoneId; // Foreign key to ref_zone_type
  int? statut;
  double? gpsLatitude;
  double? gpsLongitude;
  List<String> pieceIdentiteUrls; // Multiple photo paths
  DateTime? dateInscription;
  String creePar;
  DateTime? dateMaj;
  String? majPar;

  ContribuableEntity({
    super.id,
    this.nif,
    this.typeNif,
    required this.typeContribuable,
    this.nom,
    this.postNom,
    this.prenom,
    this.raisonSociale,
    required this.telephone1,
    this.telephone2,
    this.email,
    required this.adresse,
    required this.origineFiche,
    this.activiteId,
    this.zoneId,
    this.statut,
    this.gpsLatitude,
    this.gpsLongitude,
    List<String>? pieceIdentiteUrls,
    this.dateInscription,
    super.createdAt,
    required this.creePar,
    this.dateMaj,
    this.majPar,
    super.updatedAt,
  }) : pieceIdentiteUrls = pieceIdentiteUrls ?? [];

  /// Get the full name for display
  String get fullName {
    if (typeContribuable == TypeContribuable.morale) {
      return raisonSociale ?? 'N/A';
    }
    return [nom, postNom, prenom].where((s) => s != null && s.isNotEmpty).join(' ');
  }

  /// Get the main/first photo
  String? get mainPhoto => pieceIdentiteUrls.isNotEmpty ? pieceIdentiteUrls.first : null;

  /// Check if has GPS coordinates
  bool get hasLocation => gpsLatitude != null && gpsLongitude != null;

  @override
  String get tableName => 'contribuables';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nif': nif,
      'type_nif': typeNif?.value,
      'type_contribuable': typeContribuable.value,
      'nom': nom,
      'post_nom': postNom,
      'prenom': prenom,
      'raison_sociale': raisonSociale,
      'telephone1': telephone1,
      'telephone2': telephone2,
      'email': email,
      'adresse': adresse,
      'origine_fiche': origineFiche.value,
      'activite_id': activiteId,
      'zone_id': zoneId,
      'statut': statut,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'piece_identite_url': pieceIdentiteUrls.isNotEmpty ? jsonEncode(pieceIdentiteUrls) : null,
      'date_inscription': dateInscription?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'cree_par': creePar,
      'date_maj': dateMaj?.toIso8601String(),
      'maj_par': majPar,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ContribuableEntity.fromMap(Map<String, dynamic> map) {
    // Parse photo URLs from JSON string
    List<String> parsedPhotoUrls = [];
    final photoData = map['piece_identite_url'];
    if (photoData != null && photoData is String && photoData.isNotEmpty) {
      try {
        if (photoData.startsWith('[')) {
          parsedPhotoUrls = List<String>.from(jsonDecode(photoData));
        } else {
          parsedPhotoUrls = [photoData];
        }
      } catch (e) {
        parsedPhotoUrls = [photoData];
      }
    }

    return ContribuableEntity(
      id: map['id'] as int?,
      nif: map['nif'] as String?,
      typeNif: TypeNif.fromString(map['type_nif'] as String?),
      typeContribuable: TypeContribuable.fromString(map['type_contribuable'] as String),
      nom: map['nom'] as String?,
      postNom: map['post_nom'] as String?,
      prenom: map['prenom'] as String?,
      raisonSociale: map['raison_sociale'] as String?,
      telephone1: map['telephone1'] as String,
      telephone2: map['telephone2'] as String?,
      email: map['email'] as String?,
      adresse: map['adresse'] as String,
      origineFiche: OrigineFiche.fromString(map['origine_fiche'] as String),
      activiteId: map['activite_id'] as int?,
      zoneId: map['zone_id'] as int?,
      statut: map['statut'] as int?,
      gpsLatitude: map['gps_latitude'] != null ? (map['gps_latitude'] as num).toDouble() : null,
      gpsLongitude: map['gps_longitude'] != null ? (map['gps_longitude'] as num).toDouble() : null,
      pieceIdentiteUrls: parsedPhotoUrls,
      dateInscription: map['date_inscription'] != null
          ? DateTime.parse(map['date_inscription'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      creePar: map['cree_par'] as String? ?? 'SYSTEM',
      dateMaj: map['date_maj'] != null
          ? DateTime.parse(map['date_maj'] as String)
          : null,
      majPar: map['maj_par'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Create a copy with updated fields
  ContribuableEntity copyWith({
    int? id,
    String? nif,
    TypeNif? typeNif,
    TypeContribuable? typeContribuable,
    String? nom,
    String? postNom,
    String? prenom,
    String? raisonSociale,
    String? telephone1,
    String? telephone2,
    String? email,
    String? adresse,
    OrigineFiche? origineFiche,
    int? activiteId,
    int? zoneId,
    int? statut,
    double? gpsLatitude,
    double? gpsLongitude,
    List<String>? pieceIdentiteUrls,
    DateTime? dateInscription,
    DateTime? createdAt,
    String? creePar,
    DateTime? dateMaj,
    String? majPar,
    DateTime? updatedAt,
  }) {
    return ContribuableEntity(
      id: id ?? this.id,
      nif: nif ?? this.nif,
      typeNif: typeNif ?? this.typeNif,
      typeContribuable: typeContribuable ?? this.typeContribuable,
      nom: nom ?? this.nom,
      postNom: postNom ?? this.postNom,
      prenom: prenom ?? this.prenom,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      telephone1: telephone1 ?? this.telephone1,
      telephone2: telephone2 ?? this.telephone2,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      origineFiche: origineFiche ?? this.origineFiche,
      activiteId: activiteId ?? this.activiteId,
      zoneId: zoneId ?? this.zoneId,
      statut: statut ?? this.statut,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      pieceIdentiteUrls: pieceIdentiteUrls ?? this.pieceIdentiteUrls,
      dateInscription: dateInscription ?? this.dateInscription,
      createdAt: createdAt ?? this.createdAt,
      creePar: creePar ?? this.creePar,
      dateMaj: dateMaj ?? this.dateMaj,
      majPar: majPar ?? this.majPar,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
