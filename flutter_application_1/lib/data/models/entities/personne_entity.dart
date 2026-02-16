import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart'; // contains TypePersonne

class PersonneEntity extends BaseEntity {
  TypePersonne typePersonne;
  String? nomRaisonSociale;
  String? nif;
  String? contact;
  String? adressePostale;
  int? parcelleId;         // FK to ParcelleEntity.id (int)

  PersonneEntity({
    super.id,
    required this.typePersonne,
    this.nomRaisonSociale,
    this.nif,
    this.contact,
    this.adressePostale,
    this.parcelleId,
    super.createdAt,
    super.updatedAt,
  });

  String get displayName => 
      nomRaisonSociale ?? (typePersonne == TypePersonne.morale ? 'Société inconnue' : 'Personne inconnue');

  @override
  String get tableName => 'personnes';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type_personne': typePersonne.value,
      'nom_raison_sociale': nomRaisonSociale,
      'nif': nif,
      'contact': contact,
      'adresse_postale': adressePostale,
      'parcelle_id': parcelleId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PersonneEntity.fromMap(Map<String, dynamic> map) {
    return PersonneEntity(
      id: map['id'] as int?,
      typePersonne: TypePersonne.fromString(map['type_personne'] as String?),
      nomRaisonSociale: map['nom_raison_sociale'] as String?,
      nif: map['nif'] as String?,
      contact: map['contact'] as String?,
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

  PersonneEntity copyWith({
    int? id,
    TypePersonne? typePersonne,
    String? nomRaisonSociale,
    String? nif,
    String? contact,
    String? adressePostale,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? parcelleId,
  }) {
    return PersonneEntity(
      id: id ?? this.id,
      typePersonne: typePersonne ?? this.typePersonne,
      nomRaisonSociale: nomRaisonSociale ?? this.nomRaisonSociale,
      nif: nif ?? this.nif,
      contact: contact ?? this.contact,
      adressePostale: adressePostale ?? this.adressePostale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parcelleId: parcelleId ?? this.parcelleId,
    );
  }
}