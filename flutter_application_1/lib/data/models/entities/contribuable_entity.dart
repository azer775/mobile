import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart'; // contains TypeContribuable

class ContribuableEntity extends BaseEntity {
  TypeContribuable typeContribuable;
  // Physique fields
  String? nom;
  String? prenom;
  String? pieceIdentite;
  // Morale field
  String? nomRaisonSociale;
  String? nif;
  String? contact;
  String? email;
  String? adressePostale;
  int? parcelleId;         // FK to ParcelleEntity.id (int)

  ContribuableEntity({
    super.id,
    required this.typeContribuable,
    this.nom,
    this.prenom,
    this.pieceIdentite,
    this.nomRaisonSociale,
    this.nif,
    this.contact,
    this.email,
    this.adressePostale,
    this.parcelleId,
    super.createdAt,
    super.updatedAt,
  });

  String get displayName {
    if (typeContribuable == TypeContribuable.morale) {
      return nomRaisonSociale ?? 'Société inconnue';
    }
    final parts = [nom, prenom].where((s) => s != null && s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Contribuable inconnu';
  }

  @override
  String get tableName => 'contribuables';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type_contribuable': typeContribuable.value,
      'nom': nom,
      'prenom': prenom,
      'piece_identite': pieceIdentite,
      'nom_raison_sociale': nomRaisonSociale,
      'nif': nif,
      'contact': contact,
      'email': email,
      'adresse_postale': adressePostale,
      'parcelle_id': parcelleId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDto() {
    final dto = <String, dynamic>{
      'typeContribuable': typeContribuable.value,
    };

    void addIfNotNull(String key, dynamic value) {
      if (value != null) {
        dto[key] = value;
      }
    }

    addIfNotNull('nom', nom);
    addIfNotNull('prenom', prenom);
    addIfNotNull('pieceIdentite', pieceIdentite);
    addIfNotNull('nomRaisonSociale', nomRaisonSociale);
    addIfNotNull('nif', nif);
    addIfNotNull('contact', contact);
    addIfNotNull('email', email);
    addIfNotNull('adressePostale', adressePostale);

    return dto;
  }

  factory ContribuableEntity.fromMap(Map<String, dynamic> map) {
    return ContribuableEntity(
      id: map['id'] as int?,
      typeContribuable: TypeContribuable.fromString(map['type_contribuable'] as String?),
      nom: map['nom'] as String?,
      prenom: map['prenom'] as String?,
      pieceIdentite: map['piece_identite'] as String?,
      nomRaisonSociale: map['nom_raison_sociale'] as String?,
      nif: map['nif'] as String?,
      contact: map['contact'] as String?,
      email: map['email'] as String?,
      parcelleId: map['parcelle_id'] as int?,
      adressePostale: map['adresse_postale'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  ContribuableEntity copyWith({
    int? id,
    TypeContribuable? typeContribuable,
    String? nom,
    String? prenom,
    String? pieceIdentite,
    String? nomRaisonSociale,
    String? nif,
    String? contact,
    String? email,
    String? adressePostale,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? parcelleId,
  }) {
    return ContribuableEntity(
      id: id ?? this.id,
      typeContribuable: typeContribuable ?? this.typeContribuable,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      pieceIdentite: pieceIdentite ?? this.pieceIdentite,
      nomRaisonSociale: nomRaisonSociale ?? this.nomRaisonSociale,
      nif: nif ?? this.nif,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      adressePostale: adressePostale ?? this.adressePostale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parcelleId: parcelleId ?? this.parcelleId,
    );
  }
}
