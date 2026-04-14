import '../base/base_entity.dart';
import '../enums/parcelle_enums.dart';
import 'contribuable_entity.dart';

class UniteEntity extends BaseEntity {
  int? batimentId; // FK to BatimentEntity.id
  TypeUnite? typeUnite;
  double? superficie;
  // Locataire section
  int? contribuableId; // FK to ContribuableEntity.id (locataire)
  ContribuableEntity? locataire; // transient – carries form data before persistence
  double? montantLoyer;
  DateTime? dateDebutLoyer;

  UniteEntity({
    super.id,
    this.batimentId,
    this.typeUnite,
    this.superficie,
    this.contribuableId,
    this.locataire,
    this.montantLoyer,
    this.dateDebutLoyer,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get tableName => 'unites';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batiment_id': batimentId,
      'type_unite': typeUnite?.value,
      'superficie': superficie,
      'contribuable_id': contribuableId,
      'montant_loyer': montantLoyer,
      'date_debut_loyer': dateDebutLoyer?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDto() {
    final dto = <String, dynamic>{};

    void addIfNotNull(String key, dynamic value) {
      if (value != null) {
        dto[key] = value;
      }
    }

    addIfNotNull('typeUnite', typeUnite?.value);
    addIfNotNull('superficie', superficie);
    addIfNotNull('contribuableId', contribuableId);
    addIfNotNull('montantLoyer', montantLoyer);
    addIfNotNull('dateDebutLoyer', dateDebutLoyer?.toIso8601String());
    if (locataire != null) {
      dto['locataire'] = locataire!.toDto();
    }

    return dto;
  }

  factory UniteEntity.fromMap(Map<String, dynamic> map) {
    return UniteEntity(
      id: map['id'] as int?,
      batimentId: map['batiment_id'] as int?,
      typeUnite: map['type_unite'] != null
          ? TypeUnite.fromString(map['type_unite'] as String?)
          : null,
      superficie: map['superficie'] != null
          ? (map['superficie'] as num).toDouble()
          : null,
      contribuableId: map['contribuable_id'] as int?,
      montantLoyer: map['montant_loyer'] != null
          ? (map['montant_loyer'] as num).toDouble()
          : null,
      dateDebutLoyer: map['date_debut_loyer'] != null
          ? DateTime.parse(map['date_debut_loyer'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  UniteEntity copyWith({
    int? id,
    int? batimentId,
    TypeUnite? typeUnite,
    double? superficie,
    int? contribuableId,
    ContribuableEntity? locataire,
    double? montantLoyer,
    DateTime? dateDebutLoyer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UniteEntity(
      id: id ?? this.id,
      batimentId: batimentId ?? this.batimentId,
      typeUnite: typeUnite ?? this.typeUnite,
      superficie: superficie ?? this.superficie,
      contribuableId: contribuableId ?? this.contribuableId,
      locataire: locataire ?? this.locataire,
      montantLoyer: montantLoyer ?? this.montantLoyer,
      dateDebutLoyer: dateDebutLoyer ?? this.dateDebutLoyer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
